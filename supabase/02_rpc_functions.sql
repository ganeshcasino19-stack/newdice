-- =====================================================
-- Supabase RPC函数部署脚本
-- India Dice Game Project - 第2部分
-- =====================================================

-- =====================================================
-- 步骤 3: 创建RPC函数
-- =====================================================

-- 3.1 余额增减函数
CREATE OR REPLACE FUNCTION increment_user_balance(
  _user_id UUID,
  _delta NUMERIC
)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET balance = balance + _delta
  WHERE id = _user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.2 Dice游戏下注
CREATE OR REPLACE FUNCTION place_bet_now(
  _user_id UUID,
  _email TEXT,
  _bet_type TEXT,
  _choice INTEGER,
  _amount NUMERIC,
  _odds NUMERIC
)
RETURNS VOID AS $$
DECLARE
  _round TEXT;
  _sec INTEGER;
  _balance NUMERIC;
BEGIN
  _round := TO_CHAR((NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata'), 'YYYYMMDDHH24MI');
  _sec := EXTRACT(SECOND FROM (NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata'))::INTEGER;
  
  IF _sec > 50 THEN
    RAISE EXCEPTION 'BET_CLOSED';
  END IF;
  
  SELECT balance INTO _balance FROM users WHERE id = _user_id FOR UPDATE;
  IF _balance < _amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;
  
  UPDATE users SET balance = balance - _amount WHERE id = _user_id;
  
  INSERT INTO bets (user_id, email, round_number, bet_type, choice, amount, odds)
  VALUES (_user_id, _email, _round, _bet_type, _choice, _amount, _odds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.3 Andar Bahar下注
CREATE OR REPLACE FUNCTION ab_place_bet_ist(
  _user_id UUID,
  _email TEXT,
  _side TEXT,
  _amount NUMERIC,
  _odds NUMERIC
)
RETURNS VOID AS $$
DECLARE
  _round TEXT;
  _sec INTEGER;
  _balance NUMERIC;
BEGIN
  _round := TO_CHAR((NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata'), 'YYYYMMDDHH24MI');
  _sec := EXTRACT(SECOND FROM (NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata'))::INTEGER;
  
  IF _sec > 50 THEN
    RAISE EXCEPTION 'BET_CLOSED';
  END IF;
  
  SELECT balance INTO _balance FROM users WHERE id = _user_id FOR UPDATE;
  IF _balance < _amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;
  
  UPDATE users SET balance = balance - _amount WHERE id = _user_id;
  
  INSERT INTO ab_bets (user_id, email, round_number, side, amount, odds)
  VALUES (_user_id, _email, _round, _side, _amount, _odds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.4 Mini Wheel下注
CREATE OR REPLACE FUNCTION wheel_place_bet_ist(
  _user_id UUID,
  _email TEXT,
  _multiplier NUMERIC,
  _amount NUMERIC,
  _bet_type TEXT,
  _pick INTEGER
)
RETURNS VOID AS $$
DECLARE
  _round TEXT;
  _ist TIMESTAMPTZ;
  _minute INTEGER;
  _second INTEGER;
  _balance NUMERIC;
  _remaining INTEGER;
BEGIN
  _ist := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata';
  _minute := EXTRACT(MINUTE FROM _ist)::INTEGER;
  _second := EXTRACT(SECOND FROM _ist)::INTEGER;
  
  _round := TO_CHAR(_ist - INTERVAL '1 minute' * (_minute % 2) - INTERVAL '1 second' * _second, 'YYYYMMDDHH24MI');
  
  _remaining := 120 - ((_minute % 2) * 60 + _second);
  IF _remaining <= 30 THEN
    RAISE EXCEPTION 'BET_CLOSED';
  END IF;
  
  SELECT balance INTO _balance FROM users WHERE id = _user_id FOR UPDATE;
  IF _balance < _amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;
  
  UPDATE users SET balance = balance - _amount WHERE id = _user_id;
  
  INSERT INTO wheel_bets (user_id, email, round_number, bet_type, pick, multiplier, amount)
  VALUES (_user_id, _email, _round, _bet_type, _pick, _multiplier, _amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.5 WinGo下注
CREATE OR REPLACE FUNCTION color2m_place_bet_ist(
  _user_id UUID,
  _email TEXT,
  _bet_type TEXT,
  _choice TEXT,
  _amount NUMERIC,
  _odds NUMERIC
)
RETURNS VOID AS $$
DECLARE
  _round TEXT;
  _ist TIMESTAMPTZ;
  _minute INTEGER;
  _second INTEGER;
  _remaining INTEGER;
  _balance NUMERIC;
BEGIN
  _ist := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata';
  _minute := EXTRACT(MINUTE FROM _ist)::INTEGER;
  _second := EXTRACT(SECOND FROM _ist)::INTEGER;
  
  _round := TO_CHAR(_ist - INTERVAL '1 minute' * (_minute % 2) - INTERVAL '1 second' * _second, 'YYYYMMDDHH24MI');
  
  _remaining := 120 - ((_minute % 2) * 60 + _second);
  IF _remaining <= 30 THEN
    RAISE EXCEPTION 'BET_CLOSED';
  END IF;
  
  SELECT balance INTO _balance FROM users WHERE id = _user_id FOR UPDATE;
  IF _balance < _amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;
  
  UPDATE users SET balance = balance - _amount WHERE id = _user_id;
  
  INSERT INTO color2m_bets (user_id, email, round_number, bet_type, choice, amount, odds)
  VALUES (_user_id, _email, _round, _bet_type, _choice, _amount, _odds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.6 AB游戏：我的最近下注
CREATE OR REPLACE FUNCTION ab_my_last_bets(
  _user_id UUID,
  _limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  round_number TEXT,
  side TEXT,
  amount NUMERIC,
  result_side TEXT,
  status TEXT,
  payout NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.round_number,
    b.side,
    b.amount,
    r.result_side,
    b.status,
    b.payout
  FROM ab_bets b
  LEFT JOIN ab_rounds r ON b.round_number = r.round_number
  WHERE b.user_id = _user_id
  ORDER BY b.created_at DESC
  LIMIT _limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.7 Wheel游戏：我的最近下注
CREATE OR REPLACE FUNCTION wheel_my_last_bets(
  _user_id UUID,
  _limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  round_number TEXT,
  bet_type TEXT,
  pick INTEGER,
  multiplier NUMERIC,
  amount NUMERIC,
  result_number INTEGER,
  result_multiplier INTEGER,
  status TEXT,
  payout NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.round_number,
    b.bet_type,
    b.pick,
    b.multiplier,
    b.amount,
    b.result_number,
    b.result_multiplier,
    b.status,
    b.payout
  FROM wheel_bets b
  WHERE b.user_id = _user_id
  ORDER BY b.created_at DESC
  LIMIT _limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.8 WinGo：获取上一期期号
CREATE OR REPLACE FUNCTION color2m_prev_round_ist()
RETURNS TEXT AS $$
DECLARE
  _ist TIMESTAMPTZ;
  _minute INTEGER;
  _second INTEGER;
BEGIN
  _ist := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata';
  _minute := EXTRACT(MINUTE FROM _ist)::INTEGER;
  _second := EXTRACT(SECOND FROM _ist)::INTEGER;
  
  RETURN TO_CHAR(
    _ist - INTERVAL '1 minute' * (_minute % 2) - INTERVAL '1 second' * _second - INTERVAL '2 minutes',
    'YYYYMMDDHH24MI'
  );
END;
$$ LANGUAGE plpgsql;

-- 3.9 提现请求
CREATE OR REPLACE FUNCTION request_withdraw(
  _user_id UUID,
  _amount NUMERIC
)
RETURNS VOID AS $$
DECLARE
  _balance NUMERIC;
  _turnover NUMERIC;
  _email TEXT;
  _upi TEXT;
BEGIN
  SELECT balance, turnover_remaining, email, upi
  INTO _balance, _turnover, _email, _upi
  FROM users
  WHERE id = _user_id
  FOR UPDATE;
  
  IF _turnover > 0 THEN
    RAISE EXCEPTION 'TURNOVER_REQUIRED: %.2f', _turnover;
  END IF;
  
  IF _balance < _amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;
  
  INSERT INTO withdraw_requests (user_id, email, amount, upi)
  VALUES (_user_id, _email, _amount, _upi);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.10 领取奖金
CREATE OR REPLACE FUNCTION claim_bonus(
  p_bonus_id BIGINT
)
RETURNS JSON AS $$
DECLARE
  v_bonus RECORD;
BEGIN
  SELECT * INTO v_bonus FROM bonuses WHERE id = p_bonus_id FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BONUS_NOT_FOUND';
  END IF;
  
  IF v_bonus.status != 'pending' THEN
    RAISE EXCEPTION 'BONUS_ALREADY_CLAIMED';
  END IF;
  
  IF v_bonus.expires_at IS NOT NULL AND v_bonus.expires_at < NOW() THEN
    UPDATE bonuses SET status = 'expired' WHERE id = p_bonus_id;
    RAISE EXCEPTION 'BONUS_EXPIRED';
  END IF;
  
  UPDATE bonuses
  SET status = 'claimed', claimed_at = NOW()
  WHERE id = p_bonus_id;
  
  UPDATE users
  SET 
    balance = balance + v_bonus.amount,
    turnover_remaining = turnover_remaining + (v_bonus.amount * v_bonus.turnover_requirement)
  WHERE id = v_bonus.user_id;
  
  RETURN json_build_object(
    'success', true,
    'amount', v_bonus.amount,
    'turnover_added', v_bonus.amount * v_bonus.turnover_requirement
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.11 Three Dice自动推进
CREATE OR REPLACE FUNCTION rpc_td_tick()
RETURNS JSON AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
  v_latest RECORD;
  v_new_start TIMESTAMPTZ;
  v_new_lock TIMESTAMPTZ;
  v_new_draw TIMESTAMPTZ;
  v_new_key TEXT;
BEGIN
  SELECT * INTO v_latest
  FROM three_dice_public_rounds
  ORDER BY start_at DESC
  LIMIT 1;
  
  IF v_latest IS NULL THEN
    v_new_start := DATE_TRUNC('minute', v_now);
    v_new_start := v_new_start + INTERVAL '2 minutes' * FLOOR(EXTRACT(MINUTE FROM v_new_start)::INTEGER / 2);
    v_new_lock := v_new_start + INTERVAL '1 minute 30 seconds';
    v_new_draw := v_new_start + INTERVAL '2 minutes';
    v_new_key := TO_CHAR(v_new_start AT TIME ZONE 'Asia/Kolkata', 'YYYYMMDDHH24MI');
    
    INSERT INTO three_dice_public_rounds (round_key, start_at, lock_at, draw_at, status)
    VALUES (v_new_key, v_new_start, v_new_lock, v_new_draw, 'open');
    
    RETURN json_build_object('action', 'created_first', 'round_key', v_new_key);
  END IF;
  
  IF v_now >= v_latest.draw_at THEN
    v_new_start := v_latest.start_at + INTERVAL '2 minutes';
    v_new_lock := v_new_start + INTERVAL '1 minute 30 seconds';
    v_new_draw := v_new_start + INTERVAL '2 minutes';
    v_new_key := TO_CHAR(v_new_start AT TIME ZONE 'Asia/Kolkata', 'YYYYMMDDHH24MI');
    
    INSERT INTO three_dice_public_rounds (round_key, start_at, lock_at, draw_at, status)
    VALUES (v_new_key, v_new_start, v_new_lock, v_new_draw, 'open')
    ON CONFLICT (round_key) DO NOTHING;
    
    RETURN json_build_object('action', 'created_new', 'round_key', v_new_key);
  END IF;
  
  RETURN json_build_object('action', 'no_action', 'latest_round', v_latest.round_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 完成！下一步请执行 "03_rls_policies.sql"
-- =====================================================
