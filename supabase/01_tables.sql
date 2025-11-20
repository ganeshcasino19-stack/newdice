-- =====================================================
-- Supabase 数据库快速部署脚本
-- India Dice Game Project
-- 执行顺序：按照注释的步骤依次执行
-- =====================================================

-- =====================================================
-- 步骤 1: 创建核心表
-- =====================================================

-- 1.1 用户表
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  balance NUMERIC(12,2) DEFAULT 0 CHECK (balance >= 0),
  vip_level INTEGER DEFAULT 0 CHECK (vip_level >= 0 AND vip_level <= 10),
  name TEXT,
  ac TEXT,
  ifsc TEXT,
  upi TEXT,
  usdt_address TEXT,
  turnover_remaining NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_balance ON users(balance);

-- 1.2 更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 1.3 银行信息表
CREATE TABLE IF NOT EXISTS bank_info (
  id INTEGER PRIMARY KEY DEFAULT 1,
  name TEXT,
  ac TEXT,
  ifsc TEXT,
  upi TEXT,
  crypto_address TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT single_row CHECK (id = 1)
);

INSERT INTO bank_info (id, name, ac, ifsc, upi, crypto_address)
VALUES (1, 'Ganeshcasino', '请填写账号', 'IFSC代码', 'upi@id', 'TRC20地址')
ON CONFLICT (id) DO NOTHING;

-- 1.4 充值请求表
CREATE TABLE IF NOT EXISTS recharge_requests (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  utr TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_recharge_user ON recharge_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_recharge_status ON recharge_requests(status);
CREATE INDEX IF NOT EXISTS idx_recharge_created ON recharge_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recharge_email ON recharge_requests(email);

-- 1.5 提现请求表
CREATE TABLE IF NOT EXISTS withdraw_requests (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  upi TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_withdraw_user ON withdraw_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdraw_status ON withdraw_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdraw_created ON withdraw_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdraw_email ON withdraw_requests(email);

-- 1.6 奖金表
CREATE TABLE IF NOT EXISTS bonuses (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  bonus_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'claimed', 'expired')),
  turnover_requirement NUMERIC(12,2) DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  claimed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_bonuses_user ON bonuses(user_id);
CREATE INDEX IF NOT EXISTS idx_bonuses_status ON bonuses(status);
CREATE INDEX IF NOT EXISTS idx_bonuses_expires ON bonuses(expires_at);

-- 1.7 用户在线状态表
CREATE TABLE IF NOT EXISTS user_presence (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email TEXT,
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_agent TEXT,
  ip TEXT
);

CREATE INDEX IF NOT EXISTS idx_presence_last_seen ON user_presence(last_seen DESC);

-- =====================================================
-- 步骤 2: 创建游戏表
-- =====================================================

-- 2.1 Dice游戏
CREATE TABLE IF NOT EXISTS game_rounds (
  round_number TEXT PRIMARY KEY,
  result INTEGER CHECK (result >= 1 AND result <= 6),
  is_manual BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_rounds_created ON game_rounds(created_at DESC);

CREATE TABLE IF NOT EXISTS bets (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  round_number TEXT NOT NULL,
  bet_type TEXT NOT NULL CHECK (bet_type IN ('big', 'small', 'number')),
  choice INTEGER,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  odds NUMERIC(6,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'won', 'lost')),
  payout NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_bets_user ON bets(user_id);
CREATE INDEX IF NOT EXISTS idx_bets_round ON bets(round_number);
CREATE INDEX IF NOT EXISTS idx_bets_created ON bets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bets_status ON bets(status);

-- 2.2 Andar Bahar游戏
CREATE TABLE IF NOT EXISTS ab_rounds (
  round_number TEXT PRIMARY KEY,
  result_side TEXT CHECK (result_side IN ('andar', 'bahar', 'pending')),
  lead_rank INTEGER CHECK (lead_rank >= 1 AND lead_rank <= 13),
  match_index INTEGER,
  is_manual BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ab_rounds_created ON ab_rounds(created_at DESC);

CREATE TABLE IF NOT EXISTS ab_bets (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  round_number TEXT NOT NULL,
  side TEXT NOT NULL CHECK (side IN ('andar', 'bahar')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  odds NUMERIC(6,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'win', 'lose')),
  payout NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_ab_bets_user ON ab_bets(user_id);
CREATE INDEX IF NOT EXISTS idx_ab_bets_round ON ab_bets(round_number);
CREATE INDEX IF NOT EXISTS idx_ab_bets_created ON ab_bets(created_at DESC);

-- 2.3 Mini Wheel游戏
CREATE TABLE IF NOT EXISTS wheel_rounds (
  round_number TEXT PRIMARY KEY,
  result_index INTEGER CHECK (result_index >= 0 AND result_index <= 15),
  result_number INTEGER CHECK (result_number >= 3 AND result_number <= 18),
  result_multiplier INTEGER,
  is_manual BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wheel_rounds_created ON wheel_rounds(created_at DESC);

CREATE TABLE IF NOT EXISTS wheel_bets (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  round_number TEXT NOT NULL,
  bet_type TEXT NOT NULL CHECK (bet_type IN ('range', 'number', 'multiplier')),
  pick INTEGER,
  multiplier NUMERIC(6,2) NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'win', 'lose')),
  payout NUMERIC(12,2) DEFAULT 0,
  result_number INTEGER,
  result_multiplier INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_wheel_bets_user ON wheel_bets(user_id);
CREATE INDEX IF NOT EXISTS idx_wheel_bets_round ON wheel_bets(round_number);
CREATE INDEX IF NOT EXISTS idx_wheel_bets_created ON wheel_bets(created_at DESC);

-- 2.4 WinGo (Color2M)游戏
CREATE TABLE IF NOT EXISTS color2m_rounds (
  round_number TEXT PRIMARY KEY,
  result_number INTEGER CHECK (result_number >= 0 AND result_number <= 9),
  result_color TEXT,
  is_manual BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_color2m_rounds_created ON color2m_rounds(created_at DESC);

CREATE TABLE IF NOT EXISTS color2m_bets (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  round_number TEXT NOT NULL,
  bet_type TEXT NOT NULL CHECK (bet_type IN ('color', 'number', 'size')),
  choice TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  odds NUMERIC(6,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'win', 'lose')),
  payout NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_color2m_bets_user ON color2m_bets(user_id);
CREATE INDEX IF NOT EXISTS idx_color2m_bets_round ON color2m_bets(round_number);
CREATE INDEX IF NOT EXISTS idx_color2m_bets_created ON color2m_bets(created_at DESC);

-- 2.5 Three Dice游戏
CREATE TABLE IF NOT EXISTS three_dice_public_rounds (
  id BIGSERIAL PRIMARY KEY,
  round_key TEXT UNIQUE NOT NULL,
  start_at TIMESTAMPTZ NOT NULL,
  lock_at TIMESTAMPTZ NOT NULL,
  draw_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'open', 'locked', 'drawn', 'settled')),
  d1 INTEGER CHECK (d1 >= 1 AND d1 <= 6),
  d2 INTEGER CHECK (d2 >= 1 AND d2 <= 6),
  d3 INTEGER CHECK (d3 >= 1 AND d3 <= 6),
  total INTEGER CHECK (total >= 3 AND total <= 18),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_three_dice_rounds_key ON three_dice_public_rounds(round_key);
CREATE INDEX IF NOT EXISTS idx_three_dice_rounds_status ON three_dice_public_rounds(status);
CREATE INDEX IF NOT EXISTS idx_three_dice_rounds_lock ON three_dice_public_rounds(lock_at);

CREATE TABLE IF NOT EXISTS three_dice_bets (
  id BIGSERIAL PRIMARY KEY,
  round_id BIGINT NOT NULL REFERENCES three_dice_public_rounds(id) ON DELETE CASCADE,
  round_key TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email TEXT,
  category TEXT NOT NULL CHECK (category IN ('big_small', 'odd_even', 'sum')),
  bet_value TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  odds NUMERIC(6,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'win', 'lose')),
  payout NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_three_dice_bets_round ON three_dice_bets(round_id);
CREATE INDEX IF NOT EXISTS idx_three_dice_bets_user ON three_dice_bets(user_id);
CREATE INDEX IF NOT EXISTS idx_three_dice_bets_created ON three_dice_bets(created_at DESC);

-- =====================================================
-- 步骤 3: 创建RPC函数（下一部分继续）
-- =====================================================
-- 注意：由于SQL脚本较长，请分批执行
-- 下一步请执行 "02_rpc_functions.sql"
