import { Account, Transaction } from '../types';
import { formatNumber } from '../store';

interface Props {
  accounts: Account[];
  transactions: Transaction[];
  darkMode: boolean;
}

export default function AccountsScreen({ accounts, transactions, darkMode }: Props) {
  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);
  void darkMode;

  return (
    <div className="space-y-5">
      {/* Total */}
      <div className="rounded-3xl bg-gradient-to-br from-emerald-500 to-teal-700 p-5 shadow-xl shadow-emerald-500/30">
        <p className="text-emerald-100 text-sm mb-1">إجمالي كل الحسابات</p>
        <p className="text-white text-4xl font-black">
          {formatNumber(totalBalance)} <span className="text-2xl">ج.م</span>
        </p>
        <p className="text-emerald-200 text-xs mt-2">{accounts.length} حسابات نشطة</p>
      </div>

      {/* Account Cards */}
      <div className="grid grid-cols-1 gap-4">
        {accounts.map((acc) => {
          const accTxs = transactions.filter((t) => t.accountId === acc.id);
          const income = accTxs
            .filter((t) => t.type === 'income' && t.status !== 'pending')
            .reduce((s, t) => s + t.amount, 0);
          const expense = accTxs
            .filter((t) => t.type === 'expense' && t.status !== 'pending')
            .reduce((s, t) => s + t.amount, 0);
          const txCount = accTxs.length;

          return (
            <div
              key={acc.id}
              className="rounded-3xl overflow-hidden shadow-lg"
              style={{ background: `linear-gradient(135deg, ${acc.colors[0]}, ${acc.colors[1]})` }}
            >
              {/* Top section */}
              <div className="p-5 relative overflow-hidden">
                <div className="absolute -top-6 -right-6 text-9xl opacity-10 pointer-events-none">{acc.icon}</div>
                <div className="relative z-10 flex items-start justify-between">
                  <div>
                    <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center text-2xl mb-3">
                      {acc.icon}
                    </div>
                    <p className="text-white/80 text-sm">{acc.name}</p>
                    <p className="text-white text-3xl font-black mt-1">
                      {formatNumber(acc.balance)}{' '}
                      <span className="text-xl font-bold">{acc.currency}</span>
                    </p>
                  </div>
                  <div className="bg-white/20 rounded-xl px-3 py-1">
                    <p className="text-white/80 text-xs">{txCount} معاملة</p>
                  </div>
                </div>
              </div>

              {/* Bottom Stats */}
              <div className="bg-black/20 grid grid-cols-2 divide-x divide-x-reverse divide-white/10">
                <div className="px-4 py-3">
                  <p className="text-white/60 text-xs">إجمالي الدخل</p>
                  <p className="text-green-300 font-bold text-sm mt-0.5">+{formatNumber(income)} {acc.currency}</p>
                </div>
                <div className="px-4 py-3">
                  <p className="text-white/60 text-xs">إجمالي المصروف</p>
                  <p className="text-red-300 font-bold text-sm mt-0.5">-{formatNumber(expense)} {acc.currency}</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
