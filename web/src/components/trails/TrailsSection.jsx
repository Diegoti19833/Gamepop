import React from 'react'
import TrailCard from './TrailCard'
import MascotCTA from './MascotCTA'
import { Headphones, ShoppingBag, PawPrint, Play, Star, Trophy } from 'lucide-react'

export default function TrailsSection({ nodes = [], navigate }) {
  const meta = [
    { title: 'Atendimento', icon: '🐾', level: 2, progress: 65, xp: 650 },
    { title: 'Vendas', icon: '💰', level: 3, progress: 40, xp: 400 },
    { title: 'Produtos Pet', icon: '🦴', level: 1, progress: 25, xp: 250 },
  ]
  return (
    <section className="container page">
      <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', gap:12, marginBottom:8}}>
        <h2 className="title">Trilhas de Aprendizado 🐾</h2>
        <div className="badge" style={{fontWeight:700}}><span aria-hidden>⭐</span> XP total: 1300</div>
      </div>
      <div className="badge mission"><span className="icon-circle" aria-hidden>🎯</span> Missão do dia: Ganhe 10 XP hoje para manter sua sequência!</div>

      <div className="grid gap-4 sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
        {meta.map((m) => (
          <TrailCard
            key={m.title}
            title={m.title}
            icon={m.icon}
            progress={m.progress}
            xp={m.xp}
            level={m.level}
            onContinue={() => navigate('/aula')}
          />
        ))}
      </div>
      <MascotCTA />
      <div style={{marginTop:10, textAlign:'center'}} className="subtitle">🐶 Continue treinando para desbloquear o próximo prêmio!</div>
    </section>
  )
}