import { useState } from 'react';
import { storage } from '../store';

interface LoginScreenProps {
  onLogin: () => void;
}

export default function LoginScreen({ onLogin }: LoginScreenProps) {
  const [isLogin, setIsLogin] = useState(true);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'error' | 'success' } | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const showToast = (msg: string, type: 'error' | 'success' = 'error') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3500);
  };

  const handleAuth = async () => {
    if (!username.trim() || !password.trim()) {
      showToast('يرجى إدخال اسم المستخدم وكلمة المرور.', 'error');
      return;
    }
    if (password.length < 6) {
      showToast('كلمة المرور يجب أن تكون 6 أحرف على الأقل.', 'error');
      return;
    }
    setIsLoading(true);
    // Fake network delay for the professional loading animation
    await new Promise((r) => setTimeout(r, 1500));

    const storedUsers: Record<string, string> = JSON.parse(
      localStorage.getItem('mb_users') || '{}'
    );

    if (isLogin) {
      if (!storedUsers[username]) {
        showToast('لم يتم العثور على حساب بهذا المستخدم.', 'error');
        setIsLoading(false);
        return;
      }
      if (storedUsers[username] !== password) {
        showToast('كلمة المرور غير صحيحة.', 'error');
        setIsLoading(false);
        return;
      }
    } else {
      if (storedUsers[username]) {
        showToast('اسم المستخدم مستخدم بالفعل.', 'error');
        setIsLoading(false);
        return;
      }
      storedUsers[username] = password;
      localStorage.setItem('mb_users', JSON.stringify(storedUsers));
      showToast('تم إنشاء الحساب بنجاح! ✨ جاري الدخول...', 'success');
      await new Promise((r) => setTimeout(r, 1200));
    }

    if (rememberMe) {
      localStorage.setItem('mb_remember_me', 'true');
    }

    storage.setLoggedIn(username);
    setIsLoading(false);
    onLogin();
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-purple-950 to-slate-900 p-4">
      {/* Toast Notification */}
      {toast && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50 animate-bounce">
          <div className={`px-6 py-3 rounded-full shadow-2xl backdrop-blur-xl border flex items-center gap-3 ${
            toast.type === 'error'
              ? 'bg-red-500/20 border-red-500/50 text-red-100'
              : 'bg-green-500/20 border-green-500/50 text-green-100'
          }`}>
            <span className="text-xl">{toast.type === 'error' ? '⚠️' : '✅'}</span>
            <span className="font-bold text-sm whitespace-nowrap">{toast.msg}</span>
          </div>
        </div>
      )}

      {/* Animated background blobs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-96 h-96 bg-purple-600 rounded-full opacity-10 blur-3xl animate-pulse" />
        <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-indigo-600 rounded-full opacity-10 blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-violet-600 rounded-full opacity-5 blur-3xl animate-pulse" style={{ animationDelay: '2s' }} />
      </div>

      <div className="relative w-full max-w-md">
        {/* Card */}
        <div className="bg-white/10 backdrop-blur-2xl border border-white/20 rounded-3xl shadow-2xl p-8">
          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-violet-500 to-purple-700 flex items-center justify-center shadow-lg shadow-purple-500/40 mb-4 text-4xl">
              💰
            </div>
            <h1 className="text-3xl font-black text-white tracking-widest">MONEY BRAVO</h1>
            <p className="text-purple-300 text-sm mt-1">نظام إدارة الحسابات الاحترافي</p>
          </div>

          {/* Toggle Login/Register */}
          <div className="flex bg-white/10 rounded-2xl p-1 mb-6">
            <button
              onClick={() => setIsLogin(true)}
              className={`flex-1 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 ${
                isLogin
                  ? 'bg-white text-purple-800 shadow-lg'
                  : 'text-white/70 hover:text-white'
              }`}
            >
              تسجيل الدخول
            </button>
            <button
              onClick={() => setIsLogin(false)}
              className={`flex-1 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 ${
                !isLogin
                  ? 'bg-white text-purple-800 shadow-lg'
                  : 'text-white/70 hover:text-white'
              }`}
            >
              إنشاء حساب
            </button>
          </div>

          {/* Fields */}
          <div className="space-y-4">
            <div className="relative">
              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-purple-300 text-lg">👤</span>
              <input
                type="text"
                placeholder="اسم المستخدم"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAuth()}
                className="w-full bg-white/10 border border-white/20 text-white placeholder-white/40 rounded-xl pr-12 pl-4 py-3.5 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/30 transition-all text-sm"
              />
            </div>
            <div className="relative">
              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-purple-300 text-lg">🔒</span>
              <input
                type={showPassword ? 'text' : 'password'}
                placeholder="كلمة المرور"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAuth()}
                className="w-full bg-white/10 border border-white/20 text-white placeholder-white/40 rounded-xl pr-12 pl-12 py-3.5 focus:outline-none focus:border-purple-400 focus:ring-2 focus:ring-purple-400/30 transition-all text-sm"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-white/40 hover:text-white transition-colors"
              >
                {showPassword ? '🙈' : '👁️'}
              </button>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between pt-2">
              <label className="flex items-center gap-2 cursor-pointer group">
                <div className="relative flex items-center justify-center">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="peer appearance-none w-4 h-4 border border-white/40 rounded bg-white/5 checked:bg-violet-500 checked:border-violet-500 transition-all cursor-pointer"
                  />
                  <span className="absolute text-white opacity-0 peer-checked:opacity-100 pointer-events-none text-[10px]">
                    ✔
                  </span>
                </div>
                <span className="text-white/70 text-sm group-hover:text-white transition-colors">تذكرني</span>
              </label>
              <button
                type="button"
                onClick={() => showToast('يرجى التواصل مع الإدارة لاستعادة كلمة المرور.', 'error')}
                className="text-purple-400 hover:text-purple-300 text-sm font-bold transition-colors"
              >
                نسيت كلمة السر؟
              </button>
            </div>
          </div>

          {/* CTA Button */}
          <button
            onClick={handleAuth}
            disabled={isLoading}
            className="w-full mt-6 py-4 rounded-2xl font-black text-white text-lg bg-gradient-to-r from-violet-600 to-purple-700 hover:from-violet-500 hover:to-purple-600 shadow-lg shadow-purple-600/40 transition-all duration-300 hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:cursor-not-allowed disabled:scale-100"
          >
            {isLogin ? 'تسجيل الدخول 🚀' : 'إنشاء حساب ✨'}
          </button>

          {/* Demo hint */}
          <div className="mt-4 text-center">
            <p className="text-white/30 text-xs">
              {isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟'}{' '}
              <button
                onClick={() => setIsLogin(!isLogin)}
                className="text-purple-400 hover:text-purple-300 font-bold underline transition-colors"
              >
                {isLogin ? 'سجّل الآن' : 'ادخل هنا'}
              </button>
            </p>
          </div>
        </div>

        {/* Footer */}
        <p className="text-center text-white/20 text-xs mt-6">
          🔐 بياناتك محفوظة محلياً على جهازك بشكل آمن
        </p>
      </div>

      {/* Full Screen Loading Overlay */}
      {isLoading && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-md transition-all">
          <div className="flex flex-col items-center bg-slate-900/80 p-8 rounded-3xl border border-white/10 shadow-2xl">
            <div className="w-16 h-16 border-4 border-violet-500/30 border-t-violet-500 rounded-full animate-spin mb-4" />
            <p className="text-white font-bold text-lg animate-pulse">
              {isLogin ? 'جاري تسجيل الدخول...' : 'جاري إنشاء الحساب...'}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
