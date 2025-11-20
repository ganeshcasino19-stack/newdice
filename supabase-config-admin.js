// supabase-config-admin.js
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

export const supabase = createClient(
  'https://iwowrqqofqzpookdhboj.supabase.co', // Your Supabase admin backend project URL
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3b3dycXFvZnF6cG9va2RoYm9qIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzYxNzIwOCwiZXhwIjoyMDc5MTkzMjA4fQ.-iQReenBWUC1nfT9j4JPchsfpEFFBRNuePmITWaETY4' // Service Role Key - KEEP SECRET!
)
