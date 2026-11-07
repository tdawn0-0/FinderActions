import { useState, useEffect } from 'react';
import type { Language } from './types';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { FinderInteractiveMockup } from './components/FinderInteractiveMockup';
import { ScriptShowcase } from './components/ScriptShowcase';
import { FeaturesBento } from './components/FeaturesBento';
import { ArchitectureView } from './components/ArchitectureView';
import { GettingStarted } from './components/GettingStarted';
import { FaqSection } from './components/FaqSection';
import { Footer } from './components/Footer';

export function App() {
  const [lang, setLang] = useState<Language>(() => {
    if (typeof window !== 'undefined') {
      const q = new URLSearchParams(window.location.search).get('lang');
      if (q === 'en' || q === 'zh') return q;
      const userLang = window.navigator?.language || '';
      if (userLang.toLowerCase().includes('zh')) return 'zh';
    }
    return 'zh';
  });

  const [dark, setDark] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      const q = new URLSearchParams(window.location.search).get('theme');
      if (q === 'dark') return true;
      if (q === 'light') return false;
    }
    try {
      return localStorage.getItem('fa-theme') === 'dark';
    } catch {
      return false;
    }
  });

  useEffect(() => {
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
  }, [lang]);

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', dark ? '#0a0a0d' : '#fafaf8');
    try {
      localStorage.setItem('fa-theme', dark ? 'dark' : 'light');
    } catch {
      // Ignore storage errors in private mode
    }
  }, [dark]);

  const toggleLanguage = () => {
    setLang((prev) => (prev === 'en' ? 'zh' : 'en'));
  };

  const toggleTheme = () => {
    setDark((prev) => !prev);
  };

  return (
    <div className="min-h-dvh flex flex-col">
      <Navbar
        lang={lang}
        dark={dark}
        onToggleLang={toggleLanguage}
        onToggleTheme={toggleTheme}
      />

      <main className="flex-1 flex flex-col">
        <div className="relative isolate">
          <div
            aria-hidden="true"
            className="hero-bg pointer-events-none absolute inset-x-0 top-0 -z-10 h-[760px]"
          />
          <Hero lang={lang} />
          <FinderInteractiveMockup lang={lang} />
        </div>

        <ScriptShowcase lang={lang} />
        <FeaturesBento lang={lang} />
        <ArchitectureView lang={lang} />
        <GettingStarted lang={lang} />
        <FaqSection lang={lang} />
      </main>

      <Footer lang={lang} />
    </div>
  );
}

export default App;
