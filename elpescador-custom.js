// El Pescador - Customizações Profissionais
(function() {
  'use strict';

  // Injetar CSS
  var css = `
    /* ========== EL PESCADOR - CSS PROFISSIONAL ========== */
    :root {
      --ep-primary: #0D4F8B;
      --ep-secondary: #1E88E5;
      --ep-accent: #FF6B35;
      --ep-success: #2E7D32;
      --ep-text: #333333;
      --ep-bg: #F5F7FA;
      --ep-shadow: 0 4px 15px rgba(0,0,0,0.1);
    }

    /* Banner de confiança */
    .ep-trust-banner {
      background: linear-gradient(90deg, var(--ep-primary), var(--ep-secondary));
      color: white;
      text-align: center;
      padding: 12px 15px;
      font-weight: 600;
      font-size: 14px;
      letter-spacing: 0.5px;
    }

    /* Header melhorado */
    header, .js-head-main {
      box-shadow: var(--ep-shadow) !important;
    }

    /* Cards de produtos */
    .js-item-product, .item-product, .js-product-item {
      border-radius: 12px !important;
      overflow: hidden;
      transition: all 0.3s ease !important;
      box-shadow: 0 2px 10px rgba(0,0,0,0.08) !important;
      background: white !important;
    }

    .js-item-product:hover, .item-product:hover {
      transform: translateY(-5px) !important;
      box-shadow: 0 8px 25px rgba(0,0,0,0.15) !important;
    }

    /* Preços destacados */
    .js-price-display, .item-price, .price {
      color: var(--ep-success) !important;
      font-weight: 700 !important;
    }

    /* Botões */
    .btn-primary, .js-addtocart, .btn-add-to-cart, .add-to-cart {
      background: linear-gradient(135deg, var(--ep-accent), #E55A2B) !important;
      border: none !important;
      border-radius: 25px !important;
      padding: 12px 28px !important;
      font-weight: 600 !important;
      text-transform: uppercase !important;
      letter-spacing: 1px !important;
      transition: all 0.3s ease !important;
      box-shadow: 0 4px 15px rgba(255, 107, 53, 0.3) !important;
    }

    .btn-primary:hover, .js-addtocart:hover {
      transform: translateY(-2px) !important;
      box-shadow: 0 6px 20px rgba(255, 107, 53, 0.4) !important;
    }

    /* Badges de confiança */
    .ep-trust-badges {
      display: flex;
      justify-content: center;
      gap: 40px;
      padding: 40px 20px;
      background: white;
      flex-wrap: wrap;
      border-top: 1px solid #eee;
      border-bottom: 1px solid #eee;
    }

    .ep-trust-badge {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      color: var(--ep-text);
      max-width: 120px;
    }

    .ep-trust-badge-icon {
      width: 50px;
      height: 50px;
      background: var(--ep-bg);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
    }

    .ep-trust-badge span {
      font-size: 13px;
      font-weight: 600;
      text-align: center;
      line-height: 1.3;
    }

    /* Footer profissional */
    footer, .js-footer {
      background: linear-gradient(180deg, #1a1a2e, #16213e) !important;
    }

    /* Responsivo */
    @media (max-width: 768px) {
      .ep-trust-badges {
        gap: 20px;
        padding: 30px 15px;
      }
      .ep-trust-banner {
        font-size: 12px;
        padding: 10px;
      }
    }
  `;

  // Adicionar CSS
  var style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  // Adicionar banner de confiança
  document.addEventListener('DOMContentLoaded', function() {
    // Banner topo
    var banner = document.createElement('div');
    banner.className = 'ep-trust-banner';
    banner.innerHTML = '🎣 FRETE GRÁTIS acima de R$ 299 &nbsp;|&nbsp; 🔒 COMPRA 100% SEGURA &nbsp;|&nbsp; 📦 ENTREGA PARA TODO BRASIL';

    var header = document.querySelector('header') || document.querySelector('.js-head-main') || document.body.firstChild;
    if (header && header.parentNode) {
      header.parentNode.insertBefore(banner, header);
    }

    // Badges de confiança
    var badges = document.createElement('div');
    badges.className = 'ep-trust-badges';
    badges.innerHTML =
      '<div class="ep-trust-badge">' +
        '<div class="ep-trust-badge-icon">🛡️</div>' +
        '<span>Site 100% Seguro</span>' +
      '</div>' +
      '<div class="ep-trust-badge">' +
        '<div class="ep-trust-badge-icon">🔒</div>' +
        '<span>Pagamento Criptografado</span>' +
      '</div>' +
      '<div class="ep-trust-badge">' +
        '<div class="ep-trust-badge-icon">💳</div>' +
        '<span>Parcele em até 12x</span>' +
      '</div>' +
      '<div class="ep-trust-badge">' +
        '<div class="ep-trust-badge-icon">🚚</div>' +
        '<span>Entrega Rápida</span>' +
      '</div>' +
      '<div class="ep-trust-badge">' +
        '<div class="ep-trust-badge-icon">🔄</div>' +
        '<span>Troca Garantida</span>' +
      '</div>';

    var footer = document.querySelector('footer') || document.querySelector('.js-footer');
    if (footer && footer.parentNode) {
      footer.parentNode.insertBefore(badges, footer);
    }
  });
})();
