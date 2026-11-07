import { useState, useEffect } from 'react';
import type { Language } from './types';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { FinderInteractiveMockup } from './components/FinderInteractiveMockup';
import { FeaturesBento } from './components/FeaturesBento';
import { ScriptShowcase } from './components/ScriptShowcase';
import { ArchitectureView } from './components/ArchitectureView';
import { GettingStarted } from './components/GettingStarted';
import { FaqSection } from './components/FaqSection';
import { Footer } from './components/Footer';

export function App() {
  const [lang, setLang] = useState<Language>(() => {
    if (typeof window !== 'undefined' && window.navigator) {
      const userLang = window.navigator.language || '';
      if (userLang.toLowerCase().includes('zh')) {
        return 'zh';
      }
    }
    return 'zh';
  });

  useEffect(() => {
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
  }, [lang]);

  const toggleLanguage = () => {
    setLang((prev) => (prev === 'en' ? 'zh' : 'en'));
  };

  return (
    <div className="min-h-screen bg-[#141415] text-[#ededed] flex flex-col antialiased">
      <Navbar lang={lang} onToggleLang={toggleLanguage} />

      <main className="flex-1 flex flex-col">
        <Hero lang={lang} />
        <FinderInteractiveMockup lang={lang} />
        <FeaturesBento lang={lang} />
        <ScriptShowcase lang={lang} />
        <ArchitectureView lang={lang} />
        <GettingStarted lang={lang} />
        <FaqSection lang={lang} />
      </main>

      <Footer lang={lang} />
    </div>
  );
}

export default App;
