// supabase-config-admin.js
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

export const supabase = createClient(
  'https://iwowrqqofqzpookdhboj.supabase.co', // 你的 Supabase 管理后台项目 URL
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3b3dycXFvZnF6cG9va2RoYm9qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTcyMDgsImV4cCI6MjA3OTE5MzIwOH0.cVmX0o6wdz-09OTY0WdEnTptAx9UeBvu0pm6Dfbn6ts' // 对应后台项目 anon 公钥
)
