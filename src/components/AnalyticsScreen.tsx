import { Transaction, Account } from '../types';
import { formatNumber } from '../store';
import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer,
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Legend,
} from 'recharts';
import { format, subMonths, startOfMonth, endOfMonth } from 'date-fns';

interface Props {
  transactions: Transaction[];
  accounts: Account[];
  darkMode: boolean;
}

const COLORS = ['#7C3AED', '#10B981', '#F59E0B', '#EF4444', '#3B82F6', '#EC4899', '#8B5CF6', '#14B8A6'];

export default function AnalyticsScreen({ transactions, accounts, darkMode }: Props) {
  const completed = transactions.filter(
    (t) => t.status === 'completed' || t.status === 'approved'
  );

  // Category breakdown
  const catMap: Record<string, number> = {};
  completed
    .filter((t) => t.type === 'expense')
    .forEach((t) => {
      catMap[t.category] = (catMap[t.category] || 0) + t.amount;
    });
  const catData = Object.entries(catMap)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);

  // Monthly income vs expense (last 6 months)
  const monthlyData = Array.from({ length: 6 }, (_, i) => {
    const date = subMonths(new Date(), 5 - i);
    const label = format(date, 'MM/yyyy');
    const start = startOfMonth(date).toISOString();
    const end = endOfMonth(date).toISOString();
    const monthTxs = completed.filter(
      (t) => t.date >= start && t.date <= end
    );
    const income = monthTxs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const expense = monthTxs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    return { label, income, expense, net: income - expense };
  });

  // Account distribution
  const accData = accounts.map((acc) => ({
    name: acc.name,
    value: Math.max(0, acc.balance),
    icon: acc.icon,
  })).filter((a) => a.value > 0);

  const totalExpense = catData.reduce((s, c) => s + c.value, 0);
  const totalIncome = completed.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);

  const card = darkMode ? 'bg-white/5 border border-white/10' : 'bg-white border border-gray-100 shadow-sm';
  const text = darkMode ? 'text-white' : 'text-gray-800';
  const sub = darkMode ? 'text-white/50' : 'text-gray-400';
  const ttStyle = {
    backgroundColor: darkMode ? '#1E293B' : '#fff',
    border: 'none',
    borderRadius: 12,
    color: darkMode ? '#fff' : '#1E293B',
    fontSize: 12,
    direction: 'rtl' as const,
  };

  return (
    <div className="space-y-5">
      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-2xl p-4 bg-gradient-to-br from-green-500 to-emerald-700 shadow-lg shadow-green-500/30">
          <p className="text-green-100 text-xs">إجمالي الدخل</p>
          <p className="text-white text-xl font-black mt-1">{formatNumber(totalIncome)}</p>
          <p className="text-green-200 text-xs">ج.م</p>
        </div>
        <div className="rounded-2xl p-4 bg-gradient-to-br from-red-500 to-rose-700 shadow-lg shadow-red-500/30">
          <p className="text-red-100 text-xs">إجمالي المصروف</p>
          <p className="text-white text-xl font-black mt-1">{formatNumber(totalExpense)}</p>
          <p className="text-red-200 text-xs">ج.م</p>
        </div>
      </div>

      {/* Monthly Bar Chart */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <h3 className={`text-sm font-bold mb-4 ${text}`}>الدخل والمصروف الشهري 📊</h3>
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={monthlyData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={darkMode ? 'rgba(255,255,255,0.05)' : '#F0F0F0'} />
            <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94A3B8' }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 10, fill: '#94A3B8' }} axisLine={false} tickLine={false} />
            <Tooltip contentStyle={ttStyle} formatter={(v: unknown) => [`${formatNumber(Number(v))} ج.م`]} />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            <Bar dataKey="income" name="دخل" fill="#10B981" radius={[4, 4, 0, 0]} />
            <Bar dataKey="expense" name="مصروف" fill="#EF4444" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Category Breakdown */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <h3 className={`text-sm font-bold mb-4 ${text}`}>المصروفات حسب الفئة 🏷️</h3>
        {catData.length === 0 ? (
          <p className={`text-center text-sm py-8 ${sub}`}>لا توجد مصروفات بعد</p>
        ) : (
          <>
            <div className="flex gap-4">
              <ResponsiveContainer width={120} height={120}>
                <PieChart>
                  <Pie data={catData} cx="50%" cy="50%" innerRadius={30} outerRadius={55} dataKey="value" paddingAngle={3}>
                    {catData.map((_, idx) => (
                      <Cell key={idx} fill={COLORS[idx % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip contentStyle={ttStyle} formatter={(v: unknown) => [`${formatNumber(Number(v))} ج.م`]} />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex-1 space-y-2">
                {catData.map((cat, idx) => {
                  const pct = totalExpense > 0 ? Math.round((cat.value / totalExpense) * 100) : 0;
                  return (
                    <div key={cat.name}>
                      <div className="flex justify-between items-center mb-1">
                        <div className="flex items-center gap-1.5">
                          <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: COLORS[idx % COLORS.length] }} />
                          <span className={`text-xs ${text}`}>{cat.name}</span>
                        </div>
                        <span className={`text-xs font-bold ${text}`}>{pct}%</span>
                      </div>
                      <div className={`h-1.5 rounded-full ${darkMode ? 'bg-white/10' : 'bg-gray-100'}`}>
                        <div
                          className="h-full rounded-full"
                          style={{ width: `${pct}%`, backgroundColor: COLORS[idx % COLORS.length] }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
            <div className="mt-4 space-y-2">
              {catData.map((cat, idx) => (
                <div key={cat.name} className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[idx % COLORS.length] }} />
                    <span className={`text-xs ${sub}`}>{cat.name}</span>
                  </div>
                  <span className={`text-xs font-bold ${text}`}>{formatNumber(cat.value)} ج.م</span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Account Distribution */}
      {accData.length > 0 && (
        <div className={`rounded-2xl p-5 ${card}`}>
          <h3 className={`text-sm font-bold mb-4 ${text}`}>توزيع أرصدة الحسابات 🏦</h3>
          <ResponsiveContainer width="100%" height={160}>
            <PieChart>
              <Pie data={accData} cx="50%" cy="50%" outerRadius={65} dataKey="value" paddingAngle={4}
                label={({ name, percent }) => `${name} (${Math.round((percent || 0) * 100)}%)`}
                labelLine={false}>
                {accData.map((_, idx) => (
                  <Cell key={idx} fill={COLORS[idx % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={ttStyle} formatter={(v: unknown) => [`${formatNumber(Number(v))} ج.م`]} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
