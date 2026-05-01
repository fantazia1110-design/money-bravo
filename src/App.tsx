import { useState, useEffect, useCallback } from 'react';
import LoginScreen from './components/LoginScreen';
import Dashboard from './components/Dashboard';
import TransactionsScreen from './components/TransactionsScreen';
import AccountsScreen from './components/AccountsScreen';
import AnalyticsScreen from './components/AnalyticsScreen';
import SettingsScreen from './components/SettingsScreen';
import AddTransactionModal from './components/AddTransactionModal';
import {
  storage,
  DEFAULT_ACCOUNTS,
  recalcAccountBalances,
} from './store';
import { Account, Transaction, ActiveTab } from './types';

type NavItem = { id: ActiveTab; label: string; icon: string };

const NAV_ITEMS: NavItem[] = [
  { id: 'dashboard', label: 'الرئيسية', icon: '🏠' },
  { id: 'transactions', label: 'المعاملات', icon: '📋' },
  { id: 'accounts', label: 'الحسابات', icon: '🏦' },
  { id: 'analytics', label: 'التحليلات', icon: '📊' },
  { id: 'settings', label: 'الإعدادات', icon: '⚙️' },
];

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(() => storage.isLoggedIn());
  const [darkMode, setDarkMode] = useState(() => storage.getDarkMode());
  const [activeTab, setActiveTab] = useState<ActiveTab>('dashboard');
  const [showAddModal, setShowAddModal] = useState(false);

  const [transactions, setTransactions] = useState<Transaction[]>(() => storage.getTransactions());
  const [accounts, setAccounts] = useState<Account[]>(() => {
    const stored = storage.getAccounts();
    return recalcAccountBalances(stored, storage.getTransactions());
  });
  const [categories, setCategories] = useState<string[]>(() => storage.getCategories());
  const [dollarRate, setDollarRate] = useState(() => storage.getDollarRate());

  // Apply dark mode class
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    storage.saveDarkMode(darkMode);
  }, [darkMode]);

  // Save transactions & recalc balances whenever they change
  const syncAfterTxChange = useCallback(
    (newTxs: Transaction[]) => {
      storage.saveTransactions(newTxs);
      const baseAccounts = storage.getAccounts().length ? storage.getAccounts() : DEFAULT_ACCOUNTS;
      const recalculated = recalcAccountBalances(baseAccounts, newTxs);
      setAccounts(recalculated);
      storage.saveAccounts(recalculated);
    },
    []
  );

  const handleAddTransactions = (newTxs: Transaction[]) => {
    setTransactions((prev) => {
      const updated = [...newTxs, ...prev];
      syncAfterTxChange(updated);
      return updated;
    });
  };

  const handleApprove = (id: string) => {
    setTransactions((prev) => {
      const updated = prev.map((t) =>
        t.id === id ? { ...t, status: 'approved' as const } : t
      );
      syncAfterTxChange(updated);
      return updated;
    });
  };

  const handleDelete = (id: string) => {
    setTransactions((prev) => {
      const updated = prev.filter((t) => t.id !== id);
      syncAfterTxChange(updated);
      return updated;
    });
  };

  const handleClearAll = () => {
    setTransactions([]);
    const reset = DEFAULT_ACCOUNTS.map((a) => ({ ...a, balance: 0 }));
    setAccounts(reset);
    storage.clearAll();
    storage.saveAccounts(reset);
  };

  const handleRateChanged = (rate: number) => {
    setDollarRate(rate);
    storage.saveDollarRate(rate);
  };

  const handleCategoriesChanged = (cats: string[]) => {
    setCategories(cats);
    storage.saveCategories(cats);
  };

  const handleLogin = () => setIsLoggedIn(true);

  const handleLogout = () => {
    storage.logout();
    setIsLoggedIn(false);
  };

  const handleToggleDark = () => setDarkMode((d) => !d);

  if (!isLoggedIn) {
    return (
      <div className={darkMode ? 'dark' : ''}>
        <LoginScreen onLogin={handleLogin} />
      </div>
    );
  }

  const bgClass = darkMode
    ? 'bg-slate-950 text-white'
    : 'bg-gray-50 text-gray-900';

  const headerClass = darkMode
    ? 'bg-slate-900/80 border-white/10'
    : 'bg-white/80 border-gray-200';

  const navClass = darkMode
    ? 'bg-slate-900/95 border-white/10'
    : 'bg-white/95 border-gray-200';

  const renderPage = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard transactions={transactions} accounts={accounts} darkMode={darkMode} />;
      case 'transactions':
        return (
          <TransactionsScreen
            transactions={transactions}
            accounts={accounts}
            darkMode={darkMode}
            onApprove={handleApprove}
            onDelete={handleDelete}
          />
        );
      case 'accounts':
        return <AccountsScreen accounts={accounts} transactions={transactions} darkMode={darkMode} />;
      case 'analytics':
        return <AnalyticsScreen transactions={transactions} accounts={accounts} darkMode={darkMode} />;
      case 'settings':
        return (
          <SettingsScreen
            dollarRate={dollarRate}
            darkMode={darkMode}
            onRateChanged={handleRateChanged}
            onClearAll={handleClearAll}
            onToggleDark={handleToggleDark}
            onLogout={handleLogout}
            categories={categories}
            onCategoriesChanged={handleCategoriesChanged}
            accounts={accounts}
          />
        );
    }
  };

  const pageTitle: Record<ActiveTab, string> = {
    dashboard: 'الرئيسية',
    transactions: 'المعاملات',
    accounts: 'الحسابات',
    analytics: 'التحليلات',
    settings: 'الإعدادات',
  };

  const pendingCount = transactions.filter((t) => t.status === 'pending').length;

  return (
    <div className={`min-h-screen font-[Cairo,sans-serif] ${bgClass}`} dir="rtl">
      {/* Top Header */}
      <header className={`fixed top-0 inset-x-0 z-40 backdrop-blur-xl border-b ${headerClass}`}>
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-2xl">💰</span>
            <span className={`font-black text-lg tracking-widest ${darkMode ? 'text-white' : 'text-gray-800'}`}>
              MONEY BRAVO
            </span>
          </div>
          <div className="flex items-center gap-2">
            {pendingCount > 0 && (
              <button
                onClick={() => setActiveTab('transactions')}
                className="flex items-center gap-1.5 bg-amber-400/20 border border-amber-400/40 text-amber-500 text-xs font-bold px-3 py-1.5 rounded-full hover:bg-amber-400/30 transition-colors"
              >
                ⏳ {pendingCount}
              </button>
            )}
            <button
              onClick={handleToggleDark}
              className={`w-9 h-9 rounded-full flex items-center justify-center transition-colors ${
                darkMode ? 'bg-white/10 hover:bg-white/20 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
              }`}
            >
              {darkMode ? '☀️' : '🌙'}
            </button>
          </div>
        </div>
      </header>

      {/* Page Content */}
      <main className="max-w-lg mx-auto px-4 pt-20 pb-28 min-h-screen">
        <div className="mb-4">
          <h1 className={`text-xl font-black ${darkMode ? 'text-white' : 'text-gray-800'}`}>
            {NAV_ITEMS.find((n) => n.id === activeTab)?.icon} {pageTitle[activeTab]}
          </h1>
        </div>
        {renderPage()}
      </main>

      {/* FAB */}
      {activeTab !== 'settings' && (
        <button
          onClick={() => setShowAddModal(true)}
          className="fixed bottom-24 left-1/2 -translate-x-1/2 z-40 w-14 h-14 rounded-full bg-gradient-to-br from-violet-600 to-purple-700 text-white text-3xl shadow-2xl shadow-purple-600/50 hover:scale-110 active:scale-95 transition-all flex items-center justify-center"
          style={{ left: 'calc(50% + 120px)' }}
        >
          +
        </button>
      )}

      {/* Bottom Nav */}
      <nav className={`fixed bottom-0 inset-x-0 z-40 backdrop-blur-xl border-t ${navClass}`}>
        <div className="max-w-lg mx-auto px-2 h-16 flex items-center">
          {NAV_ITEMS.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`flex-1 flex flex-col items-center gap-0.5 py-2 rounded-xl transition-all ${
                  isActive
                    ? darkMode
                      ? 'text-violet-400'
                      : 'text-violet-600'
                    : darkMode
                    ? 'text-white/40 hover:text-white/70'
                    : 'text-gray-400 hover:text-gray-600'
                }`}
              >
                <span className={`text-xl transition-transform ${isActive ? 'scale-125' : 'scale-100'}`}>
                  {item.icon}
                </span>
                <span className={`text-[10px] font-bold ${isActive ? 'opacity-100' : 'opacity-60'}`}>
                  {item.label}
                </span>
                {isActive && (
                  <div className={`w-1 h-1 rounded-full ${darkMode ? 'bg-violet-400' : 'bg-violet-600'}`} />
                )}
              </button>
            );
          })}
        </div>
      </nav>

      {/* Add Transaction Modal */}
      {showAddModal && (
        <AddTransactionModal
          accounts={accounts}
          dollarRate={dollarRate}
          categories={categories}
          onAdd={handleAddTransactions}
          onClose={() => setShowAddModal(false)}
        />
      )}
    </div>
  );
}
