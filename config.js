// config.js - 集中管理所有配置常量
// 注意：此文件包含敏感信息，不应提交到公共代码库

export const CONFIG = {
  // Supabase 配置
  SUPABASE: {
    URL: 'https://iwowrqqofqzpookdhboj.supabase.co',
    ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3b3dycXFvZnF6cG9va2RoYm9qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTcyMDgsImV4cCI6MjA3OTE5MzIwOH0.cVmX0o6wdz-09OTY0WdEnTptAx9UeBvu0pm6Dfbn6ts'
  },

  // 管理员配置
  ADMIN: {
    EMAIL: 'admin@gmail.com'  // 建议：将此移至环境变量或服务端验证
  },

  // 客服配置
  CUSTOMER_SERVICE: {
    TELEGRAM_URL: 'https://t.me/customerservice7777777'
  },

  // 汇率配置
  EXCHANGE_RATES: {
    USDT_TO_INR: 100  // 1 USDT = 100 ₹
  },

  // 游戏配置
  GAMES: {
    DICE: {
      BIG_ODDS: 2.00,
      SMALL_ODDS: 2.00,
      NUMBER_ODDS: 6.00,
      CLOSE_BUFFER_SEC: 10  // 封盘缓冲时间（秒）
    },
    MINI_WHEEL: {
      RANGE_ODDS: 1.9,  // Small/Big 赔率
      CLOSE_BUFFER_SEC: 30,
      NUMBERS: Array.from({ length: 16 }, (_, i) => i + 3),  // 3-18
      ODDS_MAP: new Map([
        [3, 180], [18, 180],
        [4, 60], [17, 60],
        [5, 30], [16, 30],
        [6, 18], [15, 18],
        [7, 12], [14, 12],
        [8, 9], [13, 9],
        [9, 8], [12, 8],
        [10, 7], [11, 7]
      ])
    },
    ANDAR_BAHAR: {
      ANDAR_ODDS: 1.95,
      BAHAR_ODDS: 1.95,
      CLOSE_BUFFER_SEC: 10
    },
    WINGO: {
      PERIOD_SEC: 120,  // 2分钟一期
      CLOSE_SEC: 30,    // 封盘时间
      ODDS: {
        color: { green: 2, red: 2, violet: 4.5 },
        number: 9,
        size: { big: 2, small: 2 }
      }
    }
  },

  // 时区配置
  TIMEZONE: {
    IST_OFFSET_MINUTES: 330  // IST = UTC + 5:30
  }
};

// 导出常用函数
export function getISTTime() {
  const now = new Date();
  const utcMs = now.getTime() + now.getTimezoneOffset() * 60000;
  return new Date(utcMs + CONFIG.TIMEZONE.IST_OFFSET_MINUTES * 60000);
}

export function formatCurrency(amount, currency = '₹') {
  return `${currency}${Number(amount).toFixed(2)}`;
}

export function formatUSDTRate() {
  return `1 USDT = ${CONFIG.EXCHANGE_RATES.USDT_TO_INR} ₹`;
}
