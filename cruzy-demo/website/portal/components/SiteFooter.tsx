'use client'

const SITE = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'

export default function SiteFooter() {
  return (
    <>
      <section id="cta-sec" className="container-fluid py-5">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-8 col-md-12 col-12 my-3">
              <p>Join Cruzy+ and Explore the Sea</p>
            </div>
            <div className="col-lg-4 col-md-12 col-12 my-3 text-lg-end">
              <a href="/" className="cta-join-btn hvr-shutter-out-horizontal"><span>Join Cruzy+</span></a>
            </div>
          </div>
        </div>
      </section>

      <style dangerouslySetInnerHTML={{ __html: `
        section#cta-sec { background-image: linear-gradient(to right, #dc1125, #0f559a); }
        section#cta-sec p { margin: 0; color: #fff; font-size: 21px; font-weight: 700; }
        section#cta-sec a.cta-join-btn { background-color: #dc1125; color: #fff; font-size: 21px; font-weight: 500; min-width: 210px; display: inline-block; padding: 12px 25px; }
        section#cta-sec a.cta-join-btn:before { background-color: #fff; }
        section#cta-sec a.cta-join-btn:hover,
        section#cta-sec a.cta-join-btn:focus,
        section#cta-sec a.cta-join-btn:active { color: #0f559a; }
        @media(min-width:1600px) { .foot_logo .fo_nospl_log { max-width: 150px !important; } }
      `}} />

      <footer id="site_footer" className="site_footer container-fluid">
        <div className="container footer_container">
          <div className="row pt-5">
            <div className="col-xl-4 col-lg-5 col-md-6 col-sm-12 col-12 my-3 footer_col">
              <div className="foot_logo">
                <a href={`${SITE}/index.html`}><img className="w-75" src={`${SITE}/files/images/logo-cruzy.png`} /></a>
              </div>
              <div className="address_area">
                <ul className="list-unstyled mt-4 mb-0">
                  <li><i className="fa-solid fa-envelope me-2"></i><a href="mailto:info@cruzy.com">info@cruzy.com</a></li>
                  <li><i className="fa-solid fa-phone me-2"></i><a href="tel:(855) 462-7899">855-462-7899</a></li>
                  <li><i className="fa-solid fa-phone me-2"></i><a href="tel:(501) 214-9347">International: 501-214-9347</a></li>
                  <li><i className="fa-solid fa-location-dot me-2"></i><p className="m-0">PO Box 35<br />Conway, AR 72033</p></li>
                </ul>
              </div>
            </div>
            <div className="col-xl-4 col-lg-4 col-md-6 col-sm-12 col-12 my-3 footer_col">
              <h4>Plan Your Cruise</h4>
              <div className="quick_links">
                <ul className="list-unstyled">
                  <li><a href={`${SITE}/ships/index.html`}>Carnival Ships</a></li>
                  <li><a href={`${SITE}/contact/index.html`}>Cruise Planning</a></li>
                  <li><a href="/">Join Cruzy+</a></li>
                  <li><a href={`${SITE}/plans/faq/index.html`}>FAQ</a></li>
                </ul>
              </div>
            </div>
            <div className="col-xl-4 col-lg-3 col-md-6 col-sm-12 col-12 my-3 footer_col">
              <h4>Company</h4>
              <div className="quick_links">
                <ul className="list-unstyled">
                  <li><a href={`${SITE}/index.html#about-sec`}>About</a></li>
                  <li><a href="https://www.cruzy.com/privacy-policy">Privacy &amp; Legal Notice</a></li>
                  <li><a href="https://www.cruzy.com/sitemap">Sitemap</a></li>
                </ul>
              </div>
            </div>
          </div>
          <hr />
        </div>
        <div className="container copy_container">
          <div className="row copy_right py-2">
            <div className="col-lg-6 col-md-12 my-3">
              <div className="left_copy">
                <span>Copyright &copy; 2026 <a href={`${SITE}/index.html`}>Cruzy</a>. </span>
                <span>All Rights Reserved</span>
              </div>
            </div>
            <div className="col-lg-6 col-md-12 my-3">
              <div className="right_copy">
              </div>
            </div>
          </div>
        </div>
      </footer>

      <div className="scrolltop">
        <div className="scroll icon">
          <i className="fa-solid fa-arrow-up"></i>
        </div>
      </div>
    </>
  )
}
