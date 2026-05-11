'use client'

export default function SiteHeader() {
  return (
    <header style={{ background: '#10559a' }} className="w-full">
      <div className="container mx-auto px-4 flex items-center justify-between" style={{ height: '80px' }}>
        {/* Logo */}
        <a href="https://cruzy.com" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2">
          {/* Ship icon + Cruzy wordmark matching the real site */}
          <div className="flex items-center gap-2">
            <svg width="48" height="40" viewBox="0 0 48 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M24 4L28 12H36L30 18L32 26L24 21L16 26L18 18L12 12H20L24 4Z" fill="#fff" opacity="0.15"/>
              {/* Simplified ship hull */}
              <rect x="8" y="20" width="32" height="10" rx="2" fill="#fff" opacity="0.9"/>
              <rect x="14" y="14" width="12" height="8" rx="1" fill="#fff" opacity="0.9"/>
              <rect x="20" y="10" width="3" height="6" fill="#bd1f34"/>
              {/* Waves */}
              <path d="M4 32 Q8 30 12 32 Q16 34 20 32 Q24 30 28 32 Q32 34 36 32 Q40 30 44 32" stroke="#7bb3e8" strokeWidth="2" fill="none"/>
            </svg>
            <div className="flex flex-col leading-none">
              <span style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 800, fontSize: '28px', color: '#fff', letterSpacing: '-0.5px' }}>
                Cruzy
              </span>
              <span style={{ fontSize: '9px', color: '#7bb3e8', fontWeight: 400, letterSpacing: '0.5px' }}>
                Powered by Carnival
              </span>
            </div>
          </div>
        </a>

        {/* Nav links — hidden on mobile */}
        <nav className="hidden xl:flex items-center gap-1">
          {['Plans', 'Explore', 'Ships', 'Things You Need', 'Contact'].map((item) => (
            <a
              key={item}
              href={`https://cruzy.com`}
              target="_blank"
              rel="noopener noreferrer"
              className="px-5 py-2 text-white font-medium hover:text-red-400 transition-colors"
              style={{ fontSize: '16px', fontFamily: 'Poppins, sans-serif' }}
            >
              {item}
            </a>
          ))}
        </nav>

        {/* Right side: phone + buttons */}
        <div className="flex items-center">
          <a
            href="tel:8554147823"
            className="hidden md:block text-white mr-4 hover:text-red-300 transition-colors"
            style={{ fontSize: '16px', fontFamily: 'Poppins, sans-serif' }}
          >
            855-514-7823
          </a>
          <a
            href="/login"
            className="hidden md:block text-white mr-4 hover:text-red-300 transition-colors"
            style={{ fontSize: '15px' }}
          >
            Login
          </a>
          {/* Book Your Cruise — red button */}
          <a
            href="https://cruzy.com/book"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden xl:flex flex-col items-center justify-center text-white font-bold text-center leading-tight px-8 self-stretch"
            style={{ background: '#bd1f34', fontSize: '15px', fontFamily: 'Poppins, sans-serif', minWidth: '120px' }}
          >
            <span>Book Your</span>
            <span>Cruise</span>
          </a>
          {/* Join Cruzy+ — navy button */}
          <a
            href="/join-cruzy"
            className="hidden xl:flex flex-col items-center justify-center text-white font-bold text-center leading-tight px-8 self-stretch"
            style={{ background: '#10559a', fontSize: '15px', fontFamily: 'Poppins, sans-serif', minWidth: '100px', borderLeft: '2px solid rgba(255,255,255,0.2)' }}
          >
            <span>Join</span>
            <span>Cruzy+</span>
          </a>
        </div>
      </div>
    </header>
  )
}
