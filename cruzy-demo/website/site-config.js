/*
 * Cruzy Site Configuration
 * ========================
 * Change these URLs when deploying to production.
 * Every page loads this file, so one change here updates the entire site.
 */
var CRUZY = {
  siteUrl:   '',                       // leave empty = same origin (relative links work)
  portalUrl: 'https://cruzy-portal.vercel.app'
};

(function() {
  var P = CRUZY.portalUrl.replace(/\/+$/, '');

  document.querySelectorAll('a[href*="http://localhost:3000"]').forEach(function(el) {
    el.href = el.href.replace('http://localhost:3000', P);
  });

  document.querySelectorAll('form[action*="http://localhost:3000"]').forEach(function(el) {
    el.action = el.action.replace('http://localhost:3000', P);
  });
})();
