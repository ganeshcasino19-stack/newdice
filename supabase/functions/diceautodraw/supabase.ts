// supabase.ts - 服务端连接客户端
// @ts-ignore - Deno环境会自动解析ESM模块
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

export function getSupabaseClient() {
  return createClient(
    'https://iwowrqqofqzpookdhboj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3b3dycXFvZnF6cG9va2RoYm9qIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzYxNzIwOCwiZXhwIjoyMDc5MTkzMjA4fQ.-iQReenBWUC1nfT9j4JPchsfpEFFBRNuePmITWaETY4'
  )
}
