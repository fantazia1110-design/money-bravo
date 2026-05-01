import { Account, Transaction } from './types';

// ===================== DEFAULT DATA =====================
export const DEFAULT_ACCOUNTS: Account[] = [
  {
    id: 'vodafone',
    name: 'فودافون كاش',
    currency: 'ج.م',
    icon: '📱',
    colors: ['#E60000', '#990000'],
    balance: 0,
  },
  {
    id: 'instapay',
    name: 'إنستاباي',
    currency: 'ج.م',
    icon: '⚡',
    colors: ['#6D28D9', '#4C1D95'],
    balance: 0,
  },
  {
    id: 'dollar',
    name: 'حساب الدولار',
    currency: '$',
    icon: '💵',
    colors: ['#10B981', '#047857'],
    balance: 0,
  },
  {
    id: 'cash',
    name: 'كاش معانا',
    currency: 'ج.م',
    icon: '💰',
    colors: ['#F59E0B', '#B45309'],
    balance: 0,
  },
];

export const DEFAULT_CATEGORIES = [
  'رواتب',
  'إعلانات',
  'مشتريات',
  'إيجار',
  'تحويلات',
  'أخرى',
];

// ===================== LOCAL STORAGE =====================
const STORAGE_KEYS = {
  TRANSACTIONS: 'mb_transactions',
  ACCOUNTS: 'mb_accounts',
  CATEGORIES: 'mb_categories',
  DOLLAR_RATE: 'mb_dollar_rate',
  DARK_MODE: 'mb_dark_mode',
  LOGGED_IN: 'mb_logged_in',
};

export const storage = {
  getTransactions: (): Transaction[] => {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.TRANSACTIONS);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  },
  saveTransactions: (txs: Transaction[]) => {
    localStorage.setItem(STORAGE_KEYS.TRANSACTIONS, JSON.stringify(txs));
  },
  getAccounts: (): Account[] => {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.ACCOUNTS);
      const accounts = raw ? JSON.parse(raw) : DEFAULT_ACCOUNTS;
      const order: Record<string, number> = { 'vodafone': 1, 'instapay': 2, 'dollar': 3, 'cash': 4 };
      return accounts.sort((a: Account, b: Account) => (order[a.id] || 99) - (order[b.id] || 99));
    } catch {
      return DEFAULT_ACCOUNTS;
    }
  },
  saveAccounts: (accounts: Account[]) => {
    localStorage.setItem(STORAGE_KEYS.ACCOUNTS, JSON.stringify(accounts));
  },
  getCategories: (): string[] => {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.CATEGORIES);
      return raw ? JSON.parse(raw) : DEFAULT_CATEGORIES;
    } catch {
      return DEFAULT_CATEGORIES;
    }
  },
  saveCategories: (cats: string[]) => {
    localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(cats));
  },
  getDollarRate: (): number => {
    const raw = localStorage.getItem(STORAGE_KEYS.DOLLAR_RATE);
    return raw ? parseFloat(raw) : 50;
  },
  saveDollarRate: (rate: number) => {
    localStorage.setItem(STORAGE_KEYS.DOLLAR_RATE, String(rate));
  },
  getDarkMode: (): boolean => {
    const raw = localStorage.getItem(STORAGE_KEYS.DARK_MODE);
    if (raw !== null) return raw === 'true';
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  },
  saveDarkMode: (dark: boolean) => {
    localStorage.setItem(STORAGE_KEYS.DARK_MODE, String(dark));
  },
  isLoggedIn: (): boolean => {
    return !!localStorage.getItem(STORAGE_KEYS.LOGGED_IN);
  },
  setLoggedIn: (username: string) => {
    localStorage.setItem(STORAGE_KEYS.LOGGED_IN, username);
  },
  logout: () => {
    localStorage.removeItem(STORAGE_KEYS.LOGGED_IN);
  },
  getUsername: (): string => {
    return localStorage.getItem(STORAGE_KEYS.LOGGED_IN) || 'مستخدم';
  },
  updateProfile: (oldUser: string, newUser: string, newPass?: string) => {
    const users = JSON.parse(localStorage.getItem('mb_users') || '{}');
    if (users[oldUser]) {
      const passToSave = newPass ? newPass : users[oldUser];
      if (oldUser !== newUser) delete users[oldUser];
      users[newUser] = passToSave;
      localStorage.setItem('mb_users', JSON.stringify(users));
      localStorage.setItem(STORAGE_KEYS.LOGGED_IN, newUser);
    }
  },
  clearAll: () => {
    localStorage.removeItem(STORAGE_KEYS.TRANSACTIONS);
    localStorage.removeItem(STORAGE_KEYS.ACCOUNTS);
  },
};

// ===================== HELPERS =====================
export function recalcAccountBalances(
  accounts: Account[],
  transactions: Transaction[]
): Account[] {
  return accounts.map((acc) => {
    const accTxs = transactions.filter((t) => t.accountId === acc.id);
    const balance = accTxs.reduce((sum, t) => {
      if (t.status === 'completed' || t.status === 'approved') {
        return t.type === 'income' ? sum + t.amount : sum - t.amount;
      }
      return sum;
    }, 0);
    return { ...acc, balance };
  });
}

export function formatNumber(num: number): string {
  return new Intl.NumberFormat('ar-EG', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(num);
}

export function formatCurrency(amount: number, currency: string): string {
  return `${formatNumber(Math.abs(amount))} ${currency}`;
}

export function formatDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleString('ar-EG', {
    weekday: 'long',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

export function generateId(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}
