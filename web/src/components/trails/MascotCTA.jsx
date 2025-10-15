import React from 'react'

export default function MascotCTA() {
  return (
    <div className="mt-8 flex items-center justify-center gap-3 text-sm text-gray-700">
      <span className="relative inline-grid place-items-center w-10 h-10 rounded-full bg-emerald-100 text-2xl shadow-soft animate-bounce" aria-label="Mascote Pop Dog">🐶</span>
      <span className="px-3 py-2 rounded-full bg-emerald-50 text-emerald-700 font-semibold shadow-soft">Continue para ganhar XP!</span>
    </div>
  )
}