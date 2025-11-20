-- =====================================================
-- Supabase RLS策略和视图部署脚本
-- India Dice Game Project - 第3部分
-- =====================================================

-- =====================================================
-- 步骤 4: 启用RLS并创建策略
-- =====================================================

-- 4.1 启用RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ab_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wheel_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE color2m_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE three_dice_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE recharge_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdraw_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE ab_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE wheel_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE color2m_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE three_dice_public_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_info ENABLE ROW LEVEL SECURITY;

-- 4.2 Users表策略
DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- 4.3 Bets表策略
DROP POLICY IF EXISTS "Users can view own bets" ON bets;
CREATE POLICY "Users can view own bets"
  ON bets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own AB bets" ON ab_bets;
CREATE POLICY "Users can view own AB bets"
  ON ab_bets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own wheel bets" ON wheel_bets;
CREATE POLICY "Users can view own wheel bets"
  ON wheel_bets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own color2m bets" ON color2m_bets;
CREATE POLICY "Users can view own color2m bets"
  ON color2m_bets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own three dice bets" ON three_dice_bets;
CREATE POLICY "Users can view own three dice bets"
  ON three_dice_bets FOR SELECT
  USING (auth.uid() = user_id);

-- 4.4 充值提现策略
DROP POLICY IF EXISTS "Users can view own recharge requests" ON recharge_requests;
CREATE POLICY "Users can view own recharge requests"
  ON recharge_requests FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own withdraw requests" ON withdraw_requests;
CREATE POLICY "Users can view own withdraw requests"
  ON withdraw_requests FOR SELECT
  USING (auth.uid() = user_id);

-- 4.5 奖金策略
DROP POLICY IF EXISTS "Users can view own bonuses" ON bonuses;
CREATE POLICY "Users can view own bonuses"
  ON bonuses FOR SELECT
  USING (auth.uid() = user_id);

-- 4.6 游戏回合表（公开只读）
DROP POLICY IF EXISTS "Anyone can view game rounds" ON game_rounds;
CREATE POLICY "Anyone can view game rounds"
  ON game_rounds FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Anyone can view AB rounds" ON ab_rounds;
CREATE POLICY "Anyone can view AB rounds"
  ON ab_rounds FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Anyone can view wheel rounds" ON wheel_rounds;
CREATE POLICY "Anyone can view wheel rounds"
  ON wheel_rounds FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Anyone can view color2m rounds" ON color2m_rounds;
CREATE POLICY "Anyone can view color2m rounds"
  ON color2m_rounds FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Anyone can view three dice rounds" ON three_dice_public_rounds;
CREATE POLICY "Anyone can view three dice rounds"
  ON three_dice_public_rounds FOR SELECT
  TO authenticated
  USING (true);

-- 4.7 Bank info（公开只读）
DROP POLICY IF EXISTS "Anyone can view bank info" ON bank_info;
CREATE POLICY "Anyone can view bank info"
  ON bank_info FOR SELECT
  TO authenticated
  USING (true);

-- =====================================================
-- 步骤 5: 创建视图
-- =====================================================

-- 5.1 在线用户视图
CREATE OR REPLACE VIEW v_online_users AS
SELECT 
  user_id,
  email,
  last_seen,
  user_agent,
  ip
FROM user_presence
WHERE last_seen >= NOW() - INTERVAL '2 minutes'
ORDER BY last_seen DESC;

-- 5.2 在线人数统计视图
CREATE OR REPLACE VIEW v_online_count AS
SELECT COUNT(*) AS online_count
FROM user_presence
WHERE last_seen >= NOW() - INTERVAL '2 minutes';

-- =====================================================
-- 完成！数据库配置已完成
-- =====================================================
-- 
-- 下一步：
-- 1. 在Supabase Dashboard的Authentication中启用Email认证
-- 2. 上传Edge Functions到supabase/functions/目录
-- 3. 配置Cron Jobs定时任务
-- 4. 测试所有功能
-- 
-- =====================================================
