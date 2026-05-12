'use client'

import { useEffect, useState } from 'react'

const SITE = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'

export default function SiteHeader() {
  const [user, setUser] = useState<{ loggedIn: boolean; name?: string; firstName?: string } | null>(null)

  useEffect(() => {
    fetch('/api/auth/me', { credentials: 'include' })
      .then(r => r.json())
      .then(data => setUser(data))
      .catch(() => setUser({ loggedIn: false }))
  }, [])

  const loginHref = user?.loggedIn ? '/account' : '/login'
  const loginText = user?.loggedIn ? 'My Account' : 'Login'
  const joinHref = user?.loggedIn ? '/account' : '/'
  const joinText = user?.loggedIn ? 'My Account' : 'Join Cruzy+'

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: `
        .g_tr_search { display: flex; justify-content: start; align-items: center; }
        .smaller-logo { height: 60%; width: auto; }
        .menu_area a.book_cruise_btn { color: #fff; font-size: 21px; font-weight: 500; font-family: "Poppins", sans-serif; }
        .menu_area a.book_cruise_btn:hover,
        .menu_area a.book_cruise_btn:focus,
        .menu_area a.book_cruise_btn:active { color: #dc1125; text-shadow: 1px 1px 2px #000; }
        .btn-main { position: relative; }
        .cta-phone { position: absolute; top: 100%; left: -50%; font-size: 16px; transform: translateX(50%); width: 100%; }
        @media(max-width: 1400px) { .menu_area a.book_cruise_btn { font-size: 16px; } }
        @media(max-width: 980px) { .smaller-logo { max-height: 50px; } }
        @media(max-width:575px) { header.site-header .logo_area img { max-width: 200px !important; } }
        header.site-header .menu_area nav.navbar #mainmenu ul.navbar-nav li.nav-item > a.nav-link { color: #fff; font-size: 16px; font-weight: 500; font-family: "Poppins", sans-serif; padding: 18px 15px; }
        header.site-header .menu_area nav.navbar #mainmenu ul.navbar-nav li.nav-item:hover > a.nav-link,
        header.site-header .menu_area nav.navbar #mainmenu ul.navbar-nav li.nav-item:focus > a.nav-link,
        header.site-header .menu_area nav.navbar #mainmenu ul.navbar-nav li.nav-item:active > a.nav-link { color: #dc1125; text-shadow: 1px 1px 2px #000; }
        .site-header .dropdown-menu { background: #fff; border: 1px solid #ddd; border-radius: 4px; padding: 8px 0; min-width: 215px; box-shadow: 0 6px 12px rgba(0,0,0,.175); }
        .site-header .dropdown-menu .nav-link { color: #333 !important; padding: 10px 20px !important; font-size: 15px; text-shadow: none !important; }
        .site-header .dropdown-menu .nav-link:hover { color: #dc1125 !important; background: #f5f5f5; }
        @media(min-width:1200px){
          #mainmenu .g_tr_search { display: none; }
          .navbar-nav .dropdown:hover > .dropdown-menu { display: block; margin-top: 0; }
          .navbar-nav .dropdown > .dropdown-menu { transition: none; }
        }
        @media(min-width:1600px) { header.site-header .partner_logo { max-width: 325px !important; } }
      `}} />

      <header className="site-header container-fluid" id="inner_header">
        <div className="cruze-container h-100">
          <div className="d-xl-flex h-100">
            {/* Logo */}
            <div className="logo_area h-100">
              <a className="d-xl-flex align-items-center h-100" href={`${SITE}/index.html`}>
                <img src={`${SITE}/files/images/logo-cruzy.png`} className="img-fluid pe-3" alt="logo" />
              </a>
            </div>
            {/* Menu Area */}
            <div className="menu_area flex-fill">
              {/* Phone Bar (desktop) */}
              <div className="ph_area d-xl-flex d-none justify-content-end align-items-center">
                <i className="fa-solid fa-phone-volume me-2"></i>
                <a className="pe-5" href="tel:855-462-7899">855-462-7899</a>
                <a href={loginHref} className="nav-link my_account">{loginText}</a>
              </div>
              {/* Main Navigation */}
              <nav className="navbar navbar-expand-xl w-100">
                <button className="navbar-toggler collapsed shadow-none border-0" type="button"
                  data-bs-toggle="collapse" data-bs-target="#mainmenu"
                  aria-controls="mainmenu" aria-expanded="false" aria-label="Toggle navigation">
                  <span className="navbar-toggler-icon"></span>
                </button>
                <div className="collapse navbar-collapse justify-content-end" id="mainmenu">
                  <ul className="navbar-nav">
                    <li className="dropdown nav-item">
                      <a href={`${SITE}/plans/departure-ports/index.html`} className="nav-link" data-bs-toggle="dropdown">Plans</a>
                      <ul className="dropdown-menu">
                        <li className="nav-item"><a href={`${SITE}/plans/departure-ports/index.html`} className="nav-link">Departure Ports</a></li>
                        <li className="nav-item"><a href={`${SITE}/plans/popular-itineraries/index.html`} className="nav-link">Popular Itineraries</a></li>
                        <li className="nav-item"><a href={`${SITE}/plans/request-your-pcc/index.html`} className="nav-link">Request Your PCC</a></li>
                        <li className="nav-item"><a href={`${SITE}/plans/faq/index.html`} className="nav-link">FAQ</a></li>
                      </ul>
                    </li>
                    <li className="dropdown nav-item">
                      <a href={`${SITE}/explore/destination/index.html`} className="nav-link" data-bs-toggle="dropdown">Explore</a>
                      <ul className="dropdown-menu">
                        <li className="nav-item"><a href={`${SITE}/explore/destination/index.html`} className="nav-link">Destinations</a></li>
                        <li className="nav-item"><a href={`${SITE}/explore/onboard-fun/index.html`} className="nav-link">Onboard Fun</a></li>
                        <li className="nav-item"><a href={`${SITE}/explore/dining/index.html`} className="nav-link">Dining</a></li>
                      </ul>
                    </li>
                    <li className="nav-item"><a href={`${SITE}/ships/index.html`} className="nav-link">Ships</a></li>
                    <li className="nav-item"><a href={`${SITE}/things-you-need/index.html`} className="nav-link">Things You Need</a></li>
                    <li className="nav-item"><a href={`${SITE}/contact/index.html`} className="nav-link">Contact</a></li>
                  </ul>
                  {/* Mobile-only links */}
                  <div className="mob_only_js d-xl-none d-block">
                    <div className="mob_lnks">
                      <div className="ph_area my-3 d-flex align-items-center">
                        <i className="fa-solid fa-phone-volume me-2"></i>
                        <a href="tel:855-462-7899">855-462-7899</a>
                      </div>
                      <div className="ph_area my-3 d-flex align-items-center">
                        <a href={loginHref} className="nav-link my_account">{loginText}</a>
                      </div>
                      <div className="ext_btn my-2"><a href={loginHref}>Book Your Cruise</a></div>
                      <div className="ext_btn my-2"><a href={joinHref}>{joinText}</a></div>
                    </div>
                  </div>
                </div>
              </nav>
            </div>
            {/* CTA Buttons (desktop) */}
            <div className="ext_btn not_mob d-xl-flex h-100">
              <a className="d-xl-flex align-items-center hvr-shutter-in-vertical" href={loginHref}>
                <span className="button-text">Book</span>
                <span className="button-text">Your</span>
                <span className="button-text">Cruise</span>
              </a>
              <a className="d-xl-flex align-items-center hvr-shutter-in-vertical" href={joinHref}>
                {user?.loggedIn ? (
                  <>
                    <span className="button-text">My</span>
                    <span className="button-text">Account</span>
                  </>
                ) : (
                  <>
                    <span className="button-text">Join</span>
                    <span className="button-text">Cruzy+</span>
                  </>
                )}
              </a>
            </div>
          </div>
        </div>
      </header>
    </>
  )
}
