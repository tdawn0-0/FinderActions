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
    <div className="min-h-screen bg-[#090a0f] text-zinc-100 flex flex-col selection:bg-blue-600 selection:text-white font-sans antialiased">
      {/* Background ambient lighting */}
      <div 
        className="fixed top-0 left-1/2 -translate-x-1/2 w-full max-w-7xl h-[500px] pointer-events-none opacity-25 overflow-hidden -z-10"
        aria-hidden="true"
      >
        <div className="absolute top-[-20%] left-[20%] w-[600px] h-[500px] rounded-full bg-gradient-to-br from-blue-600/30 to-purple-600/20 blur-[130px]" />
        <div className="absolute top-[10%] right-[15%] w-[450px] h-[400px] rounded-full bg-gradient-to-bl from-indigo-600/20 to-sky-500/10 blur-[120px]" />
      </div>

      {/* Floating Glass Navbar */}
      <Navbar lang={lang} onToggleLang={toggleLanguage} />

      {/* Main Content Sections */}
      <main className="flex-1 flex flex-col">
        <Hero lang={lang} />
        <FinderInteractiveMockup lang={lang} />
        <ScriptShowcase lang={lang} />
        <FeaturesBento lang={lang} />
        <ArchitectureView lang={lang} />
        <GettingStarted lang={lang} />
        <FaqSection lang={lang} />
      </main>

      {/* Footer */}
      <Footer lang={lang} />
    </div>
  );
}

export default App;
