import { useState } from 'react';
import { Account, Transaction, TransactionStatus } from '../types';
import { formatNumber, formatDate } from '../store';

interface Props {
  transactions: Transaction[];
  accounts: Account[];
  darkMode: boolean;
  onApprove: (id: string) => void;
  onDelete: (id: string) => void;
}

type FilterType = 'all' | 'income' | 'expense' | 'transfer' | 'pending';

export default function TransactionsScreen({ transactions, accounts, darkMode, onApprove, onDelete }: Props) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [selectedAccount, setSelectedAccount] = useState('all');

  const filtered = transactions
    .filter((tx) => {
      const matchSearch =
        tx.description.toLowerCase().includes(search.toLowerCase()) ||
        tx.category.toLowerCase().includes(search.toLowerCase());
      const matchFilter =
        filter === 'all'
          ? true
          : filter === 'pending'
          ? tx.status === 'pending'
          : tx.type === filter;
      const matchAccount = selectedAccount === 'all' || 
                           tx.accountId === selectedAccount || 
                           (tx.type === 'transfer' && tx.toAccountId === selectedAccount);
      return matchSearch && matchFilter && matchAccount;
    })
    .sort((a, b) => b.date.localeCompare(a.date));

  const filteredIncome = filtered.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const filteredExpense = filtered.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);

  const card = darkMode ? 'bg-white/5 border border-white/10' : 'bg-white border border-gray-100 shadow-sm';
  const inputCls = darkMode
    ? 'bg-white/5 border-white/10 text-white placeholder-white/30 focus:border-purple-400'
    : 'bg-white border-gray-200 text-gray-800 placeholder-gray-400 focus:border-purple-400';

  const filters: { label: string; icon: string; value: FilterType; activeBg: string; inactiveClass: string }[] = [
    { label: 'الكل', icon: '📋', value: 'all', activeBg: 'bg-gray-600', inactiveClass: 'bg-gray-500/10 text-gray-500 border-gray-500/20' },
    { label: 'دخل', icon: '⬆️', value: 'income', activeBg: 'bg-[#00E676]', inactiveClass: 'bg-[#00E676]/15 text-[#00E676] border-[#00E676]/30' },
    { label: 'مصروف', icon: '⬇️', value: 'expense', activeBg: 'bg-[#FF1744]', inactiveClass: 'bg-[#FF1744]/15 text-[#FF1744] border-[#FF1744]/30' },
    { label: 'تحويل', icon: '↔️', value: 'transfer', activeBg: 'bg-[#2979FF]', inactiveClass: 'bg-[#2979FF]/15 text-[#2979FF] border-[#2979FF]/30' },
    { label: 'معلقة', icon: '⏳', value: 'pending', activeBg: 'bg-[#FF9100]', inactiveClass: 'bg-[#FF9100]/15 text-[#FF9100] border-[#FF9100]/30' },
  ];

  return (
    <div className="space-y-4">
      {/* Search */}
      <div className="relative">
        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="بحث في المعاملات..."
          className={`w-full rounded-2xl border pr-12 pl-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-purple-400/30 transition-all ${inputCls}`}
        />
      </div>

      {/* Account Filter */}
      <div className="flex flex-wrap gap-2 pb-1">
        <button
          onClick={() => setSelectedAccount('all')}
          className={`flex-shrink-0 px-4 py-2 rounded-2xl text-sm font-bold transition-all border ${
            selectedAccount === 'all'
              ? 'bg-purple-600 text-white shadow-lg border-transparent scale-[1.02]'
              : darkMode ? 'bg-white/5 border-white/10 text-white/60 hover:text-white' : 'bg-white border-gray-200 text-gray-500 hover:bg-gray-50'
          }`}
        >
          📋 الكل
        </button>
        {accounts.map((acc) => {
          const isSelected = selectedAccount === acc.id;
          return (
            <button
              key={acc.id}
              onClick={() => setSelectedAccount(acc.id)}
              className={`flex-shrink-0 flex items-center gap-1.5 px-4 py-2 rounded-2xl text-sm font-bold transition-all border whitespace-nowrap ${
                isSelected ? 'text-white border-transparent shadow-lg scale-[1.02]' : 'hover:scale-[1.02]'
              }`}
              style={isSelected ? { background: `linear-gradient(135deg, ${acc.colors[0]}, ${acc.colors[1]})`, boxShadow: `0 8px 15px -3px ${acc.colors[1]}50` } : { borderColor: `${acc.colors[1]}40`, backgroundColor: `${acc.colors[1]}15`, color: acc.colors[1] }}
            >
              <span>{acc.icon}</span> <span>{acc.name}</span>
            </button>
          );
        })}
      </div>

      {/* Glowing Separator */}
      <div className="h-[2px] w-full bg-gradient-to-r from-violet-500/0 via-violet-500 to-violet-500/0 shadow-[0_0_12px_rgba(139,92,246,0.8)] my-4 rounded-full" />

      {/* Type Filters */}
      <div className="flex flex-wrap gap-2 pb-1">
        {filters.map((f) => {
          const isActive = filter === f.value;
          return (
            <button
              key={f.value}
              onClick={() => setFilter(f.value)}
              className={`flex-shrink-0 flex items-center gap-1.5 px-4 py-2 rounded-2xl text-sm font-bold border transition-all ${
                isActive
                  ? `${f.activeBg} text-white border-transparent shadow-lg shadow-${f.activeBg.replace('bg-', '')}/40 scale-[1.02]`
                  : f.inactiveClass
              }`}
            >
              <span>{f.icon}</span>
              <span>{f.label}</span>
            </button>
          );
        })}
      </div>

      {/* Summary Bar */}
      <div className="bg-gradient-to-br from-[#7C3AED] to-[#4C1D95] rounded-2xl p-4 flex justify-between items-center shadow-[0_6px_20px_rgba(124,58,237,0.6)] border border-white/20 mb-4 mt-2">
        <p className="text-white font-bold text-[14px]">📊 {filtered.length} معاملة</p>
        <div className="flex gap-4">
          {filteredIncome > 0 && <p className="text-[#00E676] font-black text-[14px]">+{formatNumber(filteredIncome)}</p>}
          {filteredExpense > 0 && <p className="text-[#FF1744] font-black text-[14px]">-{formatNumber(filteredExpense)}</p>}
        </div>
      </div>

      {/* List */}
      {filtered.length === 0 ? (
        <div className={`rounded-2xl p-12 text-center ${card}`}>
          <p className="text-5xl mb-3">🔍</p>
          <p className={`text-sm ${darkMode ? 'text-white/50' : 'text-gray-400'}`}>لا توجد نتائج مطابقة</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((tx) => {
            const acc = accounts.find((a) => a.id === tx.accountId)!;
            return (
              <TxCard
                key={tx.id}
                tx={tx}
                account={acc}
                accounts={accounts}
                darkMode={darkMode}
                onApprove={onApprove}
                onDelete={onDelete}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}

function TxCard({
  tx,
  account,
  accounts,
  darkMode,
  onApprove,
  onDelete,
}: {
  tx: Transaction;
  account: Account;
  accounts: Account[];
  darkMode: boolean;
  onApprove: (id: string) => void;
  onDelete: (id: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const isIncome = tx.type === 'income';
  const isPending = tx.status === 'pending';
  const isTransfer = tx.type === 'transfer';

  // ألوان صريحة غامقة وواضحة
  const colorHex = isTransfer ? '#2979FF' : isPending ? '#F59E0B' : isIncome ? '#16A34A' : '#DC2626';
  
  const statusBadge: Record<TransactionStatus, string> = {
    completed: 'bg-white/20 text-white',
    pending: 'bg-white/20 text-white',
    approved: 'bg-white/20 text-white',
  };
  const statusLabel: Record<TransactionStatus, string> = {
    completed: 'مكتملة',
    pending: 'معلقة',
    approved: 'معتمدة',
  };
  const toAcc = accounts.find((a) => a.id === tx.toAccountId);

  return (
    <div 
      onClick={() => { if (tx.notes) setExpanded(!expanded); }}
      className={`rounded-xl flex flex-col transition-all duration-300 hover:-translate-y-0.5 hover:scale-[1.01] shadow-md ${tx.notes ? 'cursor-pointer' : ''}`}
      style={{ backgroundColor: colorHex, boxShadow: `0 4px 12px -4px ${colorHex}50` }}
    >
      <div className="p-2 flex items-start gap-2.5">
        <div
          className="w-7 h-7 mt-0.5 rounded-md flex items-center justify-center text-xs flex-shrink-0 text-white bg-white/20 shadow-sm"
        >
          {tx.type === 'transfer' ? '↔️' : isPending ? '⏳' : isIncome ? '⬆️' : '⬇️'}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex justify-between items-start mb-1.5">
            <p className="font-black text-[13px] truncate leading-tight text-white" style={{ textShadow: '0 1px 2px rgba(0,0,0,0.2)' }}>
              {tx.description}
            </p>
            <p 
              className="font-black text-[14px] leading-tight flex-shrink-0 ml-2 text-white"
              style={{ textShadow: '0 1px 2px rgba(0,0,0,0.2)' }}
            >
              {isIncome ? '+' : '-'}{formatNumber(tx.amount)} {account?.currency}
            </p>
          </div>
          <div className="flex items-center gap-1.5 flex-wrap">
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
            <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${statusBadge[tx.status]}`}>
              الحالة: {statusLabel[tx.status]}
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

      <div className="px-2 pb-2 pt-0.5">
        <div className="flex gap-1.5">
            {isPending && (
              <button
                onClick={(e) => { e.stopPropagation(); onApprove(tx.id); }}
                className="flex-1 bg-white text-[#16A34A] text-[11px] font-black py-1.5 rounded-lg transition-all hover:bg-gray-50 shadow-sm flex items-center justify-center gap-1"
              >
                <span className="text-[10px]">✅</span>
                <span>اعتماد المعاملة</span>
              </button>
            )}
            <button
              onClick={(e) => { e.stopPropagation(); onDelete(tx.id); }}
              className="flex-1 bg-white text-[#DC2626] text-[11px] font-black py-1.5 rounded-lg transition-all hover:bg-gray-50 shadow-sm flex items-center justify-center gap-1"
            >
              <span className="text-[10px]">🗑️</span>
              <span>حذف</span>
            </button>
        </div>
      </div>
    </div>
  );
}
