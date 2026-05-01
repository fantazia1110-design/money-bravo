import { useState } from 'react';
import { Account, Transaction } from '../types';
import { formatNumber, formatDate } from '../store';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { format, subDays } from 'date-fns';

interface Props {
  transactions: Transaction[];
  accounts: Account[];
  darkMode: boolean;
}

function buildChartData(transactions: Transaction[]) {
  const days = 7;
  const data = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = subDays(new Date(), i);
    const dateStr = format(date, 'yyyy-MM-dd');
    const dayTxs = transactions.filter(
      (t) => t.date.slice(0, 10) === dateStr && (t.status === 'completed' || t.status === 'approved')
    );
    const income = dayTxs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const expense = dayTxs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    data.push({ date: format(date, 'MM/dd'), income, expense });
  }
  return data;
}

export default function Dashboard({ transactions, accounts, darkMode }: Props) {
  const totalIncome = transactions
    .filter((t) => t.type === 'income' && (t.status === 'completed' || t.status === 'approved'))
    .reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions
    .filter((t) => t.type === 'expense' && (t.status === 'completed' || t.status === 'approved'))
    .reduce((s, t) => s + t.amount, 0);
  const netBalance = totalIncome - totalExpense;
  const pendingCount = transactions.filter((t) => t.status === 'pending').length;

  const chartData = buildChartData(transactions);
  const recentTxs = [...transactions].sort((a, b) => b.date.localeCompare(a.date)).slice(0, 5);

  const card = darkMode
    ? 'bg-white/5 border border-white/10'
    : 'bg-white border border-gray-100 shadow-sm';
  const sub = darkMode ? 'text-white/50' : 'text-gray-400';
  const text = darkMode ? 'text-white' : 'text-gray-800';

  return (
    <div className="space-y-6">
      {/* Hero Balance Card */}
      <div className="relative rounded-3xl overflow-hidden p-6 bg-gradient-to-br from-violet-600 via-purple-700 to-indigo-800 shadow-2xl shadow-purple-600/30">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute -top-8 -right-8 w-48 h-48 bg-white/10 rounded-full blur-2xl" />
          <div className="absolute -bottom-8 -left-8 w-40 h-40 bg-white/10 rounded-full blur-2xl" />
        </div>
        <div className="relative z-10">
          <p className="text-purple-200 text-sm mb-1">إجمالي الرصيد الصافي</p>
          <h2 className="text-4xl font-black text-white mb-1">
            {netBalance < 0 ? '-' : ''}{formatNumber(Math.abs(netBalance))}
            <span className="text-2xl mr-2 font-bold text-purple-200">ج.م</span>
          </h2>
          {pendingCount > 0 && (
            <span className="inline-block bg-amber-400/30 border border-amber-400/50 text-amber-200 text-xs px-3 py-1 rounded-full mb-4">
              ⏳ {pendingCount} معاملة معلقة
            </span>
          )}
          <div className="grid grid-cols-2 gap-3 mt-4">
            <div className="bg-white/15 rounded-2xl px-4 py-3 flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-green-400/30 flex items-center justify-center text-green-300 text-lg">↑</div>
              <div>
                <p className="text-green-200 text-xs">إجمالي الدخل</p>
                <p className="text-white font-bold text-sm">{formatNumber(totalIncome)} ج.م</p>
              </div>
            </div>
            <div className="bg-white/15 rounded-2xl px-4 py-3 flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-red-400/30 flex items-center justify-center text-red-300 text-lg">↓</div>
              <div>
                <p className="text-red-200 text-xs">إجمالي المصروف</p>
                <p className="text-white font-bold text-sm">{formatNumber(totalExpense)} ج.م</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Account Cards */}
      <div>
        <h3 className={`text-base font-bold mb-3 ${text}`}>الحسابات 🏦</h3>
        <div className="grid grid-cols-2 gap-3">
          {accounts.map((acc) => (
            <div
              key={acc.id}
              className="rounded-2xl p-4 relative overflow-hidden shadow-lg"
              style={{ background: `linear-gradient(135deg, ${acc.colors[0]}, ${acc.colors[1]})` }}
            >
              <div className="absolute -top-4 -right-4 text-6xl opacity-10">{acc.icon}</div>
              <div className="relative z-10">
                <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center text-xl mb-3">
                  {acc.icon}
                </div>
                <p className="text-white/80 text-xs">{acc.name}</p>
                <p className="text-white font-black text-lg leading-tight">
                  {formatNumber(acc.balance)} {acc.currency}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Chart */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <h3 className={`text-base font-bold mb-4 ${text}`}>حركة الأسبوع الماضي 📈</h3>
        <ResponsiveContainer width="100%" height={180}>
          <AreaChart data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="incomeGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#10B981" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="expenseGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#EF4444" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#EF4444" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke={darkMode ? 'rgba(255,255,255,0.05)' : '#F0F0F0'} />
            <XAxis dataKey="date" tick={{ fontSize: 11, fill: darkMode ? '#94A3B8' : '#94A3B8' }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 10, fill: darkMode ? '#94A3B8' : '#94A3B8' }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{
                backgroundColor: darkMode ? '#1E293B' : '#fff',
                border: 'none',
                borderRadius: 12,
                color: darkMode ? '#fff' : '#1E293B',
                fontSize: 12,
                direction: 'rtl',
              }}
              formatter={(value: unknown) => [`${formatNumber(Number(value))} ج.م`]}
            />
            <Area type="monotone" dataKey="income" stroke="#10B981" strokeWidth={2} fill="url(#incomeGrad)" name="دخل" />
            <Area type="monotone" dataKey="expense" stroke="#EF4444" strokeWidth={2} fill="url(#expenseGrad)" name="مصروف" />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Recent Transactions */}
      <div>
        <h3 className={`text-base font-bold mb-3 ${text}`}>أحدث المعاملات 🕐</h3>
        {recentTxs.length === 0 ? (
          <div className={`rounded-2xl p-8 text-center ${card}`}>
            <p className="text-4xl mb-2">📭</p>
            <p className={`text-sm ${sub}`}>لا توجد معاملات بعد</p>
            <p className={`text-xs mt-1 ${sub}`}>اضغط على زر + لإضافة أول حركة</p>
          </div>
        ) : (
          <div className="space-y-2">
            {recentTxs.map((tx) => {
              const acc = accounts.find((a) => a.id === tx.accountId)!;
              return <TransactionRow key={tx.id} tx={tx} account={acc} accounts={accounts} darkMode={darkMode} />;
            })}
          </div>
        )}
      </div>
    </div>
  );
}

function TransactionRow({ tx, account, accounts, darkMode }: { tx: Transaction; account: Account; accounts: Account[]; darkMode: boolean }) {
  const [expanded, setExpanded] = useState(false);
  const isIncome = tx.type === 'income';
  const isPending = tx.status === 'pending';
  const isTransfer = tx.type === 'transfer';

  // ألوان صريحة غامقة وواضحة
  const colorHex = isTransfer ? '#2979FF' : isPending ? '#F59E0B' : isIncome ? '#16A34A' : '#DC2626';
  const toAcc = accounts.find((a) => a.id === tx.toAccountId);

  return (
    <div 
      onClick={() => { if (tx.notes) setExpanded(!expanded); }}
      className={`rounded-lg flex flex-col transition-all duration-300 hover:-translate-y-0.5 shadow-sm ${tx.notes ? 'cursor-pointer' : ''}`}
      style={{ backgroundColor: colorHex, boxShadow: `0 2px 8px -2px ${colorHex}50` }}
    >
      <div className="p-2 flex items-start gap-2">
        <div className="w-7 h-7 mt-0.5 rounded-md flex items-center justify-center text-xs flex-shrink-0 text-white bg-white/20 shadow-sm">
          {tx.type === 'transfer' ? '↔️' : isPending ? '⏳' : isIncome ? '⬆️' : '⬇️'}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex justify-between items-start mb-1.5">
            <p className="font-black text-[13px] truncate leading-tight text-white" style={{ textShadow: '0 1px 2px rgba(0,0,0,0.2)' }}>{tx.description}</p>
            <div className="text-left flex-shrink-0 ml-2">
              <p className="font-black text-[14px] leading-tight text-white" style={{ textShadow: '0 1px 2px rgba(0,0,0,0.2)' }}>
                {isIncome ? '+' : '-'}{formatNumber(tx.amount)} {account?.currency}
              </p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-1.5">
            {tx.type === 'transfer' ? (
              <>
                <span className="text-[9px] font-bold px-1.5 py-0.5 rounded text-white shadow-sm" style={{ background: `linear-gradient(135deg, ${account.colors[0]}, ${account.colors[1]})` }}>
                  من: {account.name}
                </span>
                <div className="flex items-center justify-center w-7 h-7 rounded-full bg-gradient-to-br from-[#FF9100] to-[#FF1744] border-[1.5px] border-white shadow-md mx-1">
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M10 19l-7-7m0 0l7-7m-7 7h18" /></svg>
                </div>
                <span className="text-[9px] font-bold px-1.5 py-0.5 rounded text-white shadow-sm" style={{ background: `linear-gradient(135deg, ${toAcc?.colors[0] || '#999'}, ${toAcc?.colors[1] || '#666'})` }}>
                  إلى: {toAcc?.name}
                </span>
              </>
            ) : (
              <span className="text-[9px] font-bold px-1.5 py-0.5 rounded text-white shadow-sm" style={{ background: `linear-gradient(135deg, ${account.colors[0]}, ${account.colors[1]})` }}>
                الحساب: {account.name}
              </span>
            )}
            <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-white/20 text-white">
              الفئة: {tx.category}
            </span>
            <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-white/20 text-white">
              التاريخ: {formatDate(tx.date)}
            </span>
          </div>
        </div>
      </div>
      {expanded && tx.notes && (
        <div className="px-2 pb-2">
          <div className="bg-black/15 border border-white/10 rounded-lg p-2 mt-1">
            <p className="text-white text-[11px] font-bold">📝 ملاحظات: {tx.notes}</p>
          </div>
        </div>
      )}
    </div>
  );
}
