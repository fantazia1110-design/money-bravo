export type TransactionType = 'income' | 'expense' | 'transfer';
export type TransactionStatus = 'completed' | 'pending' | 'approved';

export interface Account {
  id: string;
  name: string;
  currency: string;
  icon: string;
  colors: [string, string];
  balance: number;
}

export interface Transaction {
  id: string;
  description: string;
  amount: number;
  type: TransactionType;
  accountId: string;
  toAccountId?: string;
  date: string; // ISO string
  status: TransactionStatus;
  category: string;
  notes: string;
  createdBy?: string;
}

export type ActiveTab = 'dashboard' | 'transactions' | 'accounts' | 'analytics' | 'settings';
