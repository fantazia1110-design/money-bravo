import { useState } from 'react';
import { storage, DEFAULT_CATEGORIES } from '../store';
import { Account } from '../types';

interface Props {
  dollarRate: number;
  darkMode: boolean;
  onRateChanged: (rate: number) => void;
  onClearAll: () => void;
  onToggleDark: () => void;
  onLogout: () => void;
  categories: string[];
  onCategoriesChanged: (cats: string[]) => void;
  accounts: Account[];
}

export default function SettingsScreen({
  dollarRate,
  darkMode,
  onRateChanged,
  onClearAll,
  onToggleDark,
  onLogout,
  categories,
  onCategoriesChanged,
}: Props) {
  const [rateInput, setRateInput] = useState(String(dollarRate));
  const [newCat, setNewCat] = useState('');
  const [showClearConfirm, setShowClearConfirm] = useState(false);
  const [rateSaved, setRateSaved] = useState(false);
  
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [newUsername, setNewUsername] = useState(storage.getUsername());
  const [newPassword, setNewPassword] = useState('');
  
  const username = storage.getUsername();

  const card = darkMode ? 'bg-white/5 border border-white/10' : 'bg-white border border-gray-100 shadow-sm';
  const text = darkMode ? 'text-white' : 'text-gray-800';
  const sub = darkMode ? 'text-white/50' : 'text-gray-400';
  const input = darkMode
    ? 'bg-white/5 border-white/10 text-white placeholder-white/30 focus:border-purple-400'
    : 'bg-gray-50 border-gray-200 text-gray-800 placeholder-gray-400 focus:border-purple-400';

  const handleSaveRate = () => {
    const r = parseFloat(rateInput);
    if (!isNaN(r) && r > 0) {
      onRateChanged(r);
      setRateSaved(true);
      setTimeout(() => setRateSaved(false), 2000);
    }
  };

  const handleSaveProfile = () => {
    if (newUsername.trim()) {
      storage.updateProfile(username, newUsername.trim(), newPassword);
      setIsEditingProfile(false);
      setNewPassword('');
      // Force reload to show new username safely
      window.location.reload(); 
    }
  };

  const handleAddCat = () => {
    if (newCat.trim() && !categories.includes(newCat.trim())) {
      onCategoriesChanged([...categories, newCat.trim()]);
      setNewCat('');
    }
  };

  const handleDeleteCat = (cat: string) => {
    if (DEFAULT_CATEGORIES.includes(cat)) return;
    onCategoriesChanged(categories.filter((c) => c !== cat));
  };

  return (
    <div className="space-y-4">
      {/* User Card */}
      <div className={`rounded-2xl p-5 ${card}`}>
        {!isEditingProfile ? (
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-3xl bg-gradient-to-br from-violet-500 to-purple-700 flex items-center justify-center text-3xl shadow-xl shadow-purple-500/40 relative group cursor-pointer" onClick={() => setIsEditingProfile(true)}>
              👤
              <div className="absolute inset-0 bg-black/40 rounded-3xl flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                <span className="text-white text-xs font-bold">تعديل</span>
              </div>
            </div>
            <div>
              <p className={`font-black text-xl ${text}`}>{username}</p>
              <p className={`text-sm ${sub}`}>مدير النظام</p>
            </div>
            <div className="mr-auto flex gap-2">
              <button onClick={() => setIsEditingProfile(true)} className={`p-2.5 rounded-xl transition-colors ${darkMode ? 'bg-white/10 hover:bg-white/20' : 'bg-gray-100 hover:bg-gray-200'}`}>✏️</button>
              <button onClick={onLogout} className="bg-red-100 hover:bg-red-200 text-red-600 font-bold text-sm px-4 py-2.5 rounded-xl transition-colors">🚪 خروج</button>
            </div>
          </div>
        ) : (
          <div className="space-y-4 animate-in fade-in zoom-in duration-300">
            <p className={`font-black text-lg ${text}`}>تعديل الملف الشخصي ✏️</p>
            <div>
              <label className={`block text-xs font-bold mb-1 ${sub}`}>اسم المستخدم الجديد</label>
              <input value={newUsername} onChange={(e) => setNewUsername(e.target.value)} className={`w-full border rounded-xl px-4 py-2.5 text-sm ${input}`} />
            </div>
            <div>
              <label className={`block text-xs font-bold mb-1 ${sub}`}>كلمة المرور الجديدة (اختياري)</label>
              <input type="password" placeholder="اتركها فارغة للاحتفاظ بالقديمة" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className={`w-full border rounded-xl px-4 py-2.5 text-sm ${input}`} />
            </div>
            <div className="flex gap-2 pt-2">
              <button onClick={handleSaveProfile} className="flex-1 py-2.5 bg-violet-600 hover:bg-violet-700 text-white rounded-xl font-bold text-sm transition-colors">
                حفظ التعديلات ✅
              </button>
              <button onClick={() => setIsEditingProfile(false)} className={`px-5 py-2.5 rounded-xl font-bold text-sm transition-colors ${darkMode ? 'bg-white/10 text-white hover:bg-white/20' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'}`}>
                إلغاء
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Dark Mode Toggle */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <div className="flex items-center justify-between">
          <div>
            <p className={`font-bold ${text}`}>🌙 الوضع الليلي</p>
            <p className={`text-sm mt-0.5 ${sub}`}>تبديل بين الفاتح والداكن</p>
          </div>
          <button
            onClick={onToggleDark}
            className={`relative w-14 h-7 rounded-full transition-colors duration-300 ${
              darkMode ? 'bg-violet-600' : 'bg-gray-300'
            }`}
          >
            <div
              className={`absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-all duration-300 ${
                darkMode ? 'right-0.5' : 'left-0.5'
              }`}
            />
          </button>
        </div>
      </div>

      {/* Dollar Rate */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <p className={`font-bold mb-4 ${text}`}>💱 سعر الدولار</p>
        <div className="flex gap-3">
          <div className="relative flex-1">
            <input
              type="number"
              value={rateInput}
              onChange={(e) => setRateInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveRate()}
              className={`w-full border rounded-xl px-4 py-2.5 pl-24 text-sm focus:outline-none focus:ring-2 focus:ring-purple-400/30 transition-all ${input}`}
              placeholder="سعر الدولار"
            />
            <button
              onClick={async () => {
                try {
                  const res = await fetch('https://open.er-api.com/v6/latest/USD');
                  const data = await res.json();
                  if (data?.rates?.EGP) {
                    const rate = data.rates.EGP;
                    setRateInput(rate.toFixed(2));
                    onRateChanged(rate);
                    setRateSaved(true);
                    setTimeout(() => setRateSaved(false), 2000);
                  }
                } catch (e) {
                  console.error(e);
                }
              }}
              className="absolute left-1.5 top-1.5 bottom-1.5 px-3 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-xs font-bold transition-colors flex items-center gap-1"
              title="تحديث تلقائي من الإنترنت"
            >
              <span>🌐</span> تلقائي
            </button>
          </div>
          <button
            onClick={handleSaveRate}
            className={`px-5 py-2.5 rounded-xl font-bold text-sm transition-all ${
              rateSaved
                ? 'bg-green-500 text-white'
                : 'bg-violet-600 hover:bg-violet-700 text-white'
            }`}
          >
            {rateSaved ? '✅ تم' : 'حفظ'}
          </button>
        </div>
        <p className={`text-xs mt-2 ${sub}`}>1 دولار = {dollarRate} جنيه مصري</p>
      </div>

      {/* Categories Management */}
      <div className={`rounded-2xl p-5 ${card}`}>
        <p className={`font-bold mb-4 ${text}`}>🏷️ إدارة الفئات</p>
        <div className="flex gap-2 mb-4">
          <input
            value={newCat}
            onChange={(e) => setNewCat(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleAddCat()}
            placeholder="اسم فئة جديدة..."
            className={`flex-1 border rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-purple-400/30 transition-all ${input}`}
          />
          <button
            onClick={handleAddCat}
            className="px-4 py-2.5 bg-violet-600 hover:bg-violet-700 text-white rounded-xl font-bold text-sm transition-colors"
          >
            + إضافة
          </button>
        </div>
        <div className="flex flex-wrap gap-2">
          {categories.map((cat) => {
            const isDefault = DEFAULT_CATEGORIES.includes(cat);
            return (
              <div
                key={cat}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-bold transition-all ${
                  darkMode
                    ? 'bg-white/10 text-white/80'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                <span>{cat}</span>
                {!isDefault && (
                  <button
                    onClick={() => handleDeleteCat(cat)}
                    className="text-red-400 hover:text-red-600 transition-colors leading-none"
                  >
                    ✕
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Clear Data */}
      <div className={`rounded-2xl p-5 border-2 ${darkMode ? 'border-red-900/40 bg-red-900/10' : 'border-red-100 bg-red-50'}`}>
        <p className="font-bold text-red-500 mb-1">🗑️ مسح جميع البيانات</p>
        <p className={`text-xs mb-4 ${darkMode ? 'text-red-400/70' : 'text-red-400'}`}>
          سيحذف جميع المعاملات ويعيد تعيين الأرصدة. لا يمكن التراجع عن هذا الإجراء.
        </p>
        {!showClearConfirm ? (
          <button
            onClick={() => setShowClearConfirm(true)}
            className="w-full py-2.5 rounded-xl font-bold text-sm text-red-500 border-2 border-red-300 hover:bg-red-100 transition-colors"
          >
            ⚠️ مسح النظام بالكامل
          </button>
        ) : (
          <div className="space-y-2">
            <p className="text-red-500 font-bold text-center text-sm">هل أنت متأكد تمامًا؟</p>
            <div className="flex gap-2">
              <button
                onClick={() => { onClearAll(); setShowClearConfirm(false); }}
                className="flex-1 py-2.5 rounded-xl font-bold text-sm bg-red-500 hover:bg-red-600 text-white transition-colors"
              >
                نعم، احذف كل شيء
              </button>
              <button
                onClick={() => setShowClearConfirm(false)}
                className={`flex-1 py-2.5 rounded-xl font-bold text-sm transition-colors ${
                  darkMode ? 'bg-white/10 text-white hover:bg-white/20' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                إلغاء
              </button>
            </div>
          </div>
        )}
      </div>

      {/* App Info */}
      <div className={`rounded-2xl p-4 text-center ${card}`}>
        <p className="text-2xl mb-1">💰</p>
        <p className={`font-black text-lg tracking-widest ${text}`}>MONEY BRAVO</p>
        <p className={`text-xs mt-0.5 ${sub}`}>نظام إدارة الحسابات الاحترافي v2.0</p>
        <p className={`text-xs mt-2 ${sub}`}>🔐 بياناتك محفوظة بشكل آمن على جهازك</p>
      </div>
    </div>
  );
}
