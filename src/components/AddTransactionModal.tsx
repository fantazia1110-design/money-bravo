import { useState, useEffect } from 'react';
import { Account, Transaction, TransactionType, TransactionStatus } from '../types';
import { formatNumber, generateId } from '../store';

interface Props {
  accounts: Account[];
  dollarRate: number;
  categories: string[];
  onAdd: (txs: Transaction[]) => void;
  onClose: () => void;
}

type TabType = 'income' | 'expense' | 'transfer';

export default function AddTransactionModal({ accounts, dollarRate, categories, onAdd, onClose }: Props) {
  const [type, setType] = useState<TabType>('income');
  const [fromAccountId, setFromAccountId] = useState(accounts[0]?.id || '');
  const [toAccountId, setToAccountId] = useState(accounts[1]?.id || accounts[0]?.id || '');
  const [status, setStatus] = useState<TransactionStatus>('completed');
  const [category, setCategory] = useState(categories[0] || 'أخرى');
  const [desc, setDesc] = useState('');
  const [amount, setAmount] = useState('');
  const [notes, setNotes] = useState('');
  const [dateStr, setDateStr] = useState(new Date().toISOString().slice(0, 10));
  const [error, setError] = useState('');

  const fromAccount = accounts.find((a) => a.id === fromAccountId);
  const isDollar = fromAccount?.currency === 'USD';
  const inputAmount = parseFloat(amount.replace(/,/g, '')) || 0;
  const finalAmount = inputAmount; // 🐛 إصلاح خطير: يجب حفظ المبلغ بعملته الأصلية ليتوافق مع محرك حسابات Flutter

  const availableBalance = fromAccount?.balance || 0;
  const isBalanceInsufficient = (type === 'expense' || type === 'transfer') && finalAmount > availableBalance;

  // Keep toAccountId valid
  useEffect(() => {
    if (toAccountId === fromAccountId) {
      const other = accounts.find((a) => a.id !== fromAccountId);
      if (other) setToAccountId(other.id);
    }
  }, [fromAccountId]);

  const handleSubmit = () => {
    setError('');
    if (!desc.trim()) { setError('يرجى إدخال الوصف.'); return; }
    if (inputAmount <= 0) { setError('يرجى إدخال مبلغ صحيح أكبر من صفر.'); return; }
    if (type === 'transfer' && fromAccountId === toAccountId) {
      setError('يجب أن يكون حساب المصدر مختلفًا عن حساب الوجهة.');
      return;
    }

    if (isBalanceInsufficient) {
      setError('لا يمكن إتمام العملية! المبلغ المطلوب يتخطى الرصيد المتاح بالحساب.');
      return;
    }

    // طريقة آمنة 100% مدعومة في جميع المتصفحات بما فيها Safari
    const currentObj = new Date();
    const dateObj = new Date(dateStr);
    dateObj.setHours(currentObj.getHours(), currentObj.getMinutes(), currentObj.getSeconds());
    const now = dateObj.toISOString();

    if (type === 'transfer') {
      const tx: Transaction = {
        id: generateId(),
        description: desc,
        amount: finalAmount,
        type: 'transfer' as TransactionType,
        accountId: fromAccountId,
        toAccountId: toAccountId, // ربط حساب المستقبل
        date: now,
        status,
        category: 'تحويلات',
        notes,
      };
      onAdd([tx]);
    } else {
      const tx: Transaction = {
        id: generateId(),
        description: desc,
        amount: finalAmount,
        type: type as TransactionType,
        accountId: fromAccountId,
        date: now,
        status,
        category,
        notes,
      };
      onAdd([tx]);
    }
    onClose();
  };

  const tabs: { label: string; icon: string; value: TabType; activeClass: string; inactiveClass: string }[] = [
    { label: 'دخل', icon: '⬆️', value: 'income', activeClass: 'bg-[#00E676] text-white shadow-lg shadow-[#00E676]/40 border-transparent', inactiveClass: 'bg-[#00E676]/10 text-[#00E676] border-[#00E676]/20' },
    { label: 'مصروف', icon: '⬇️', value: 'expense', activeClass: 'bg-[#FF1744] text-white shadow-lg shadow-[#FF1744]/40 border-transparent', inactiveClass: 'bg-[#FF1744]/10 text-[#FF1744] border-[#FF1744]/20' },
    { label: 'تحويل', icon: '↔️', value: 'transfer', activeClass: 'bg-[#2979FF] text-white shadow-lg shadow-[#2979FF]/40 border-transparent', inactiveClass: 'bg-[#2979FF]/10 text-[#2979FF] border-[#2979FF]/20' },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center" onClick={onClose}>
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
      <div
        className="relative w-full max-w-lg bg-white dark:bg-slate-900 rounded-t-3xl shadow-2xl overflow-hidden max-h-[92vh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-2 flex-shrink-0">
          <div className="w-10 h-1.5 rounded-full bg-gray-300" />
        </div>

        {/* Header */}
        <div className="px-5 pb-4 flex-shrink-0">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-black text-gray-800">إضافة حركة جديدة</h2>
            <button onClick={onClose} className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200 transition-colors">✕</button>
          </div>
        </div>

        {/* Scrollable body */}
        <div className="overflow-y-auto flex-1 px-5 pb-6 space-y-4">
          {/* Tabs */}
          <div className="flex gap-2 pt-2">
            {tabs.map((t) => (
              <button
                key={t.value}
                onClick={() => setType(t.value)}
                className={`flex flex-1 items-center justify-center gap-1.5 py-3 rounded-xl text-sm font-black transition-all border ${
                  type === t.value ? t.activeClass : t.inactiveClass
                }`}
              >
                <span className="text-lg">{t.icon}</span>
                <span>{t.label}</span>
              </button>
            ))}
          </div>

          {/* Description */}
          <div>
            <label className="block text-xs font-bold text-gray-500 mb-1.5">الوصف *</label>
            <input
              value={desc}
              onChange={(e) => setDesc(e.target.value)}
              placeholder="مثال: راتب شهر يناير"
              className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/20 transition-all"
            />
          </div>

          {/* Amount + Date */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-500 mb-1.5">
                المبلغ * {fromAccount?.currency && `(${fromAccount.currency})`}
              </label>
              <input
                type="text"
                inputMode="decimal"
                value={amount}
                onChange={(e) => {
                  let val = e.target.value.replace(/[^0-9.]/g, '');
                  const parts = val.split('.');
                  if (parts.length > 2) val = parts[0] + '.' + parts.slice(1).join('');
                  if (parts[0]) {
                    const num = parseInt(parts[0], 10);
                    if (!isNaN(num)) {
                      parts[0] = num.toLocaleString('en-US');
                      val = parts.join('.');
                    }
                  }
                  setAmount(val);
                }}
                placeholder="0.00"
                className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/20 transition-all"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-500 mb-1.5">التاريخ</label>
              <input
                type="date"
                value={dateStr}
                onChange={(e) => setDateStr(e.target.value)}
                className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm text-gray-800 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/20 transition-all"
              />
            </div>
          </div>

          {/* From Account */}
          <div>
            <label className="block text-xs font-bold text-gray-500 mb-1.5">
              {type === 'transfer' ? 'من حساب *' : 'الحساب *'}
            </label>
            <div className="grid grid-cols-2 gap-2">
              {accounts.map((acc) => {
                const isSelected = fromAccountId === acc.id;
                return (
                  <button
                    key={acc.id}
                    onClick={() => setFromAccountId(acc.id)}
                    className={`flex items-center gap-2 px-3 py-3 rounded-2xl text-sm font-bold transition-all border ${
                      isSelected
                        ? 'text-white shadow-lg border-transparent'
                        : 'hover:scale-105'
                    }`}
                    style={isSelected ? { background: `linear-gradient(135deg, ${acc.colors[0]}, ${acc.colors[1]})`, boxShadow: `0 8px 15px -3px ${acc.colors[1]}60` } : { borderColor: `${acc.colors[1]}40`, backgroundColor: `${acc.colors[1]}15`, color: acc.colors[1] }}
                  >
                    <span className="text-xl">{acc.icon}</span>
                    <span className="truncate">{acc.name}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* To Account (transfer only) */}
          {type === 'transfer' && (
            <div>
              <label className="block text-xs font-bold text-gray-500 mb-1.5">إلى حساب *</label>
              <div className="grid grid-cols-2 gap-2">
                {accounts.filter((a) => a.id !== fromAccountId).map((acc) => {
                  const isSelected = toAccountId === acc.id;
                  return (
                    <button
                      key={acc.id}
                      onClick={() => setToAccountId(acc.id)}
                      className={`flex items-center gap-2 px-3 py-3 rounded-2xl text-sm font-bold transition-all border ${isSelected ? 'text-white shadow-lg border-transparent' : 'hover:scale-105'}`}
                      style={isSelected ? { background: `linear-gradient(135deg, ${acc.colors[0]}, ${acc.colors[1]})`, boxShadow: `0 8px 15px -3px ${acc.colors[1]}60` } : { borderColor: `${acc.colors[1]}40`, backgroundColor: `${acc.colors[1]}15`, color: acc.colors[1] }}
                    >
                      <span className="text-xl">{acc.icon}</span>
                      <span className="truncate">{acc.name}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Category + Status */}
          {type !== 'transfer' && (
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-gray-500 mb-1.5">الفئة</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full border border-gray-200 bg-gray-50 rounded-xl px-3 py-3 text-sm text-gray-800 focus:outline-none focus:border-purple-400 transition-all"
                >
                  {categories.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-500 mb-1.5">الحالة</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as TransactionStatus)}
                  className="w-full border border-gray-200 bg-gray-50 rounded-xl px-3 py-3 text-sm text-gray-800 focus:outline-none focus:border-purple-400 transition-all"
                >
                  <option value="completed">مكتملة ✅</option>
                  <option value="pending">معلقة ⏳</option>
                </select>
              </div>
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="block text-xs font-bold text-gray-500 mb-1.5">ملاحظات إضافية</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="أي تفاصيل إضافية..."
              rows={2}
              className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/20 transition-all resize-none"
            />
          </div>

          {/* Dollar Conversion */}
          {isDollar && inputAmount > 0 && (
            <div className="bg-emerald-50 border-2 border-emerald-200 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-3">
                <span className="text-emerald-600 font-bold text-sm">🧮 تحويل الدولار التلقائي</span>
              </div>
              <div className="space-y-1.5">
                <div className="flex justify-between text-sm">
                  <span className="text-emerald-700">المبلغ المُدخل</span>
                  <span className="font-bold text-emerald-700">${formatNumber(inputAmount)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-emerald-700">سعر الصرف</span>
                  <span className="font-bold text-emerald-700">{dollarRate} ج.م / دولار</span>
                </div>
                <div className="h-px bg-emerald-200 my-1" />
                <div className="flex justify-between">
                  <span className="text-emerald-800 font-bold">🎯 المبلغ المعادل</span>
                  <span className="text-emerald-800 font-black text-lg">{formatNumber(inputAmount * dollarRate)} ج.م</span>
                </div>
              </div>
            </div>
          )}

          {/* Error */}
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">
              ⚠️ {error}
            </div>
          )}

          {isBalanceInsufficient && !error && (
            <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm font-bold flex items-center gap-2">
              <span className="text-lg">⚠️</span>
              <span>تحذير: المبلغ يتجاوز الرصيد المتاح ({formatNumber(availableBalance)} {fromAccount?.currency})</span>
            </div>
          )}

          {/* Submit */}
          <button
            onClick={handleSubmit}
            className="w-full py-4 rounded-2xl font-black text-white text-base bg-gradient-to-r from-violet-600 to-purple-700 hover:from-violet-500 hover:to-purple-600 shadow-lg shadow-purple-500/30 transition-all hover:scale-[1.02] active:scale-95"
          >
            ✅ إضافة المعاملة
          </button>
        </div>
      </div>
    </div>
  );
}
