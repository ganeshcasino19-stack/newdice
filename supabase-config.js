// supabase-config.js  —— Just overwrite this file
// Note: Frontend only uses anon key; never put service_role in the frontend!

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

// ====== Your project configuration (filled in) ======
const supabaseUrl = 'https://iwowrqqofqzpookdhboj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3b3dycXFvZnF6cG9va2RoYm9qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTcyMDgsImV4cCI6MjA3OTE5MzIwOH0.cVmX0o6wdz-09OTY0WdEnTptAx9UeBvu0pm6Dfbn6ts';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  global: {
    headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' }
  }
});

/* ===================================================================
 *                       Common helpers (optional)
 * =================================================================== */

// Current logged-in user
export async function getCurrentUser() {
  const { data } = await supabase.auth.getUser();
  return data?.user ?? null;
}

// User balance
export async function getUserBalance(userId) {
  const { data, error } = await supabase
    .from('users')
    .select('balance')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data?.balance ?? 0;
}

/* ===================================================================
 *                 Andar Bahar API (use RPC, avoid direct insert)
 * =================================================================== */

// Atomic bet (deduct + lock check + write bet slip)
// side: 'andar' | 'bahar'
export async function placeABBetNow({ userId, email, side, amount, odds }) {
  return await supabase.rpc('place_ab_bet_now', {
    _user_id: userId,
    _email: email,
    _side: side,
    _amount: amount,
    _odds: odds
  });
}

// Previous period result (pass previous round_number, return 'andar' | 'bahar' | null)
export async function getABPrevResult(prevRoundNumber) {
  const { data, error } = await supabase
    .from('ab_rounds')
    .select('result_side')
    .eq('round_number', prevRoundNumber)
    .maybeSingle();
  if (error) throw error;
  return data?.result_side ?? null;
}

// User's recent N AB bet slips (read-only)
export async function getABUserBets(userId, limit = 10) {
  const { data, error } = await supabase
    .from('ab_bets')
    .select('round_number, side, amount, status, payout, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data || [];
}

// (Optional) Read details of a specific round number
export async function getABRound(roundNumber) {
  const { data, error } = await supabase
    .from('ab_rounds')
    .select('*')
    .eq('round_number', roundNumber)
    .maybeSingle();
  if (error) throw error;
  return data ?? null;
}
