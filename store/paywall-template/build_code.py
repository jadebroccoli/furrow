"""Build code.js — RevenueCat-compatible Figma paywall generator.

v4: Stripped vectors/absolute positioning that break RC import.
Hero uses image fill (the app icon) on a simple Auto Layout frame.
All frames use proper Auto Layout with no absolute children.
Layer naming follows RevenueCat conventions exactly.
"""
from PIL import Image
import io, base64

# Generate the base64 icon (144x144 for hero display)
img = Image.open('C:/Projects/GrowLog/assets/icons/app_icon.png')
img = img.resize((144, 144), Image.LANCZOS)
buf = io.BytesIO()
img.save(buf, format='PNG', optimize=True)
b64 = base64.b64encode(buf.getvalue()).decode('ascii')

# Also make a hero background image (390x280 gradient with leaves baked in)
# We'll create a simple green gradient PNG to use as hero image fill
from PIL import ImageDraw
hero_img = Image.new('RGBA', (390, 280))
draw = ImageDraw.Draw(hero_img)
# Draw vertical gradient: forest green top -> medium green -> seedling green bottom
for y in range(280):
    if y < 168:  # 0-60% = top to mid
        t = y / 168.0
        r = int(45 + (61 - 45) * t)
        g = int(90 + (122 - 90) * t)
        b = int(39 + (53 - 39) * t)
    else:  # 60-100% = mid to bottom
        t = (y - 168) / 112.0
        r = int(61 + (102 - 61) * t)
        g = int(122 + (187 - 122) * t)
        b = int(53 + (106 - 53) * t)
    draw.line([(0, y), (389, y)], fill=(r, g, b, 255))

hero_buf = io.BytesIO()
hero_img.save(hero_buf, format='PNG', optimize=True)
hero_b64 = base64.b64encode(hero_buf.getvalue()).decode('ascii')

JS_TEMPLATE = r"""// Furrow Paywall v4 — RevenueCat-Compatible Figma Plugin Script
// No vectors, no absolute positioning, no spacer frames
// All Auto Layout, proper RC layer naming

function hex(h) {
  h = h.replace('#', '');
  return { r: parseInt(h.substring(0, 2), 16) / 255, g: parseInt(h.substring(2, 4), 16) / 255, b: parseInt(h.substring(4, 6), 16) / 255 };
}
function rgba(h, a) { var c = hex(h); return { r: c.r, g: c.g, b: c.b, a: a }; }
function solid(h, opacity) { return [{ type: 'SOLID', color: hex(h), opacity: opacity !== undefined ? opacity : 1 }]; }

var LIGHT = {
  name: 'Furrow / Paywall / Light',
  bg: '#FFF8F0', cardBg: '#FFFDF7', selectedCardBg: '#F5FFF5',
  selectedBorder: '#2D5A27', unselectedBorder: '#E0D8CC',
  headline: '#1A1C18', subtitle: '#7A8B6F', bodyText: '#3D3D3D',
  checkmark: '#66BB6A', badgeBg: '#D4A017', badgeText: '#FFFDF7',
  ctaBg: '#2D5A27', ctaText: '#FFFFFF', priceBreakdown: '#8B6914',
  footerText: '#7A8B6F', footerSep: '#C0B8A8',
  priceLabelColor: '#1A1C18', pricePeriodColor: '#7A8B6F', priceNameColor: '#7A8B6F'
};
var DARK = {
  name: 'Furrow / Paywall / Dark',
  bg: '#1A1C18', cardBg: '#121410', selectedCardBg: '#1E2A1A',
  selectedBorder: '#66BB6A', unselectedBorder: '#2A2C26',
  headline: '#FFF8F0', subtitle: '#A8B89A', bodyText: '#D4D0C8',
  checkmark: '#66BB6A', badgeBg: '#D4A017', badgeText: '#121410',
  ctaBg: '#66BB6A', ctaText: '#121410', priceBreakdown: '#CBB979',
  footerText: '#A8B89A', footerSep: '#3A3C36',
  priceLabelColor: '#FFF8F0', pricePeriodColor: '#A8B89A', priceNameColor: '#A8B89A'
};

var FONT_REGULAR, FONT_SEMI, FONT_BOLD, FONT_EXTRA;
async function loadFonts() {
  try {
    await Promise.all([
      figma.loadFontAsync({family:'Nunito',style:'Regular'}),
      figma.loadFontAsync({family:'Nunito',style:'SemiBold'}),
      figma.loadFontAsync({family:'Nunito',style:'Bold'}),
      figma.loadFontAsync({family:'Nunito',style:'ExtraBold'})
    ]);
    FONT_REGULAR={family:'Nunito',style:'Regular'};
    FONT_SEMI={family:'Nunito',style:'SemiBold'};
    FONT_BOLD={family:'Nunito',style:'Bold'};
    FONT_EXTRA={family:'Nunito',style:'ExtraBold'};
  } catch(e) {
    await Promise.all([
      figma.loadFontAsync({family:'Inter',style:'Regular'}),
      figma.loadFontAsync({family:'Inter',style:'Semi Bold'}),
      figma.loadFontAsync({family:'Inter',style:'Bold'}),
      figma.loadFontAsync({family:'Inter',style:'Extra Bold'})
    ]);
    FONT_REGULAR={family:'Inter',style:'Regular'};
    FONT_SEMI={family:'Inter',style:'Semi Bold'};
    FONT_BOLD={family:'Inter',style:'Bold'};
    FONT_EXTRA={family:'Inter',style:'Extra Bold'};
  }
}

// Create an Auto Layout frame — NO absolute positioning anywhere
function af(name, dir, o) {
  if (!o) o = {};
  var f = figma.createFrame();
  f.name = name;
  f.layoutMode = dir;
  f.primaryAxisSizingMode = o.ps || 'AUTO';
  f.counterAxisSizingMode = o.cs || 'AUTO';
  f.itemSpacing = o.gap || 0;
  f.paddingTop = o.pt || o.py || o.p || 0;
  f.paddingBottom = o.pb || o.py || o.p || 0;
  f.paddingLeft = o.pl || o.px || o.p || 0;
  f.paddingRight = o.pr || o.px || o.p || 0;
  if (o.fill) f.fills = o.fill; else f.fills = [];
  if (o.w && o.h) f.resize(o.w, o.h);
  else if (o.w) f.resize(o.w, f.height);
  else if (o.h) f.resize(f.width, o.h);
  if (o.r) f.cornerRadius = o.r;
  if (o.stroke) { f.strokes = o.stroke; f.strokeWeight = o.sw || 2; f.strokeAlign = 'INSIDE'; }
  if (o.ma) f.primaryAxisAlignItems = o.ma;
  if (o.ca) f.counterAxisAlignItems = o.ca;
  if (o.clip !== undefined) f.clipsContent = o.clip;
  return f;
}

function tx(content, font, size, fills, o) {
  if (!o) o = {};
  var t = figma.createText();
  t.fontName = font;
  t.characters = content;
  t.fontSize = size;
  t.fills = fills;
  if (o.ls) t.letterSpacing = {value: o.ls, unit: 'PIXELS'};
  if (o.lh) t.lineHeight = {value: o.lh, unit: 'PIXELS'};
  if (o.al) t.textAlignHorizontal = o.al;
  if (o.ar) t.textAutoResize = o.ar;
  if (o.name) t.name = o.name;
  return t;
}

function sH(n, m) { n.layoutSizingHorizontal = m; }
function sV(n, m) { n.layoutSizingVertical = m; }

var APP_ICON_B64 = '__ICON_B64__';
var HERO_BG_B64 = '__HERO_B64__';

function b64decode(base64) {
  var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  var lookup = {};
  for (var k = 0; k < chars.length; k++) lookup[chars.charAt(k)] = k;
  var len = base64.length;
  var pads = 0;
  if (base64.charAt(len - 1) === '=') pads++;
  if (base64.charAt(len - 2) === '=') pads++;
  var byteLen = (len * 3 / 4) - pads;
  var arr = new Uint8Array(byteLen);
  var j = 0;
  for (var i = 0; i < len; i += 4) {
    var a = lookup[base64.charAt(i)] || 0;
    var b = lookup[base64.charAt(i + 1)] || 0;
    var c = lookup[base64.charAt(i + 2)] || 0;
    var d = lookup[base64.charAt(i + 3)] || 0;
    arr[j++] = (a << 2) | (b >> 4);
    if (j < byteLen) arr[j++] = ((b & 15) << 4) | (c >> 2);
    if (j < byteLen) arr[j++] = ((c & 3) << 6) | d;
  }
  return arr;
}

function buildPaywall(theme) {
  // Root frame: 390x844, vertical Auto Layout, clips content
  var root = af(theme.name, 'VERTICAL', {
    ps: 'FIXED', cs: 'FIXED', w: 390, h: 844,
    fill: solid(theme.bg), clip: true
  });

  // ── HERO ──
  // Simple frame with image fill, centered icon
  var hero = af('Hero', 'VERTICAL', {
    ps: 'FIXED', cs: 'FIXED', w: 390, h: 280,
    ma: 'CENTER', ca: 'CENTER', clip: true
  });
  // Set hero bg as image fill (baked gradient PNG)
  var heroBgBytes = b64decode(HERO_BG_B64);
  var heroBgImage = figma.createImage(heroBgBytes);
  hero.fills = [{ type: 'IMAGE', imageHash: heroBgImage.hash, scaleMode: 'FILL' }];
  root.appendChild(hero);
  sH(hero, 'FILL');
  sV(hero, 'FIXED');

  // App icon inside hero (centered by Auto Layout)
  var iconBytes = b64decode(APP_ICON_B64);
  var iconImage = figma.createImage(iconBytes);
  var iconWrap = af('App Icon', 'VERTICAL', {
    ps: 'FIXED', cs: 'FIXED', w: 144, h: 144,
    r: 28, ma: 'CENTER', ca: 'CENTER', clip: true
  });
  iconWrap.fills = [{ type: 'IMAGE', imageHash: iconImage.hash, scaleMode: 'FILL' }];
  hero.appendChild(iconWrap);

  // ── CONTENT ──
  // Main content area with proper padding and gaps
  var cnt = af('Content', 'VERTICAL', { px: 24, pt: 20, gap: 0 });
  root.appendChild(cnt);
  sH(cnt, 'FILL');
  sV(cnt, 'HUG');

  // Headline
  var hl = tx('Grow without limits', FONT_EXTRA, 28, solid(theme.headline), {
    name: 'Headline', ar: 'WIDTH_AND_HEIGHT'
  });
  cnt.appendChild(hl);

  // Subtitle (with top spacing via a wrapper or just gap)
  var subWrap = af('Subtitle Wrap', 'VERTICAL', { pt: 8 });
  cnt.appendChild(subWrap);
  sH(subWrap, 'FILL');
  sV(subWrap, 'HUG');
  var sub = tx(
    'Unlock unlimited plants, seasons, frost alerts & more with Furrow Pro.',
    FONT_REGULAR, 16, solid(theme.subtitle),
    { name: 'Subtitle', ar: 'HEIGHT', lh: 22 }
  );
  subWrap.appendChild(sub);
  sH(sub, 'FILL');

  // Features section
  var featsWrap = af('Features Wrap', 'VERTICAL', { pt: 24 });
  cnt.appendChild(featsWrap);
  sH(featsWrap, 'FILL');
  sV(featsWrap, 'HUG');

  var feats = af('Features', 'VERTICAL', { gap: 12 });
  featsWrap.appendChild(feats);
  sH(feats, 'FILL');
  sV(feats, 'HUG');

  var items = [
    'Unlimited plants & seasons',
    'Frost alerts for every location',
    'Full harvest tracking & journal',
    'Priority support'
  ];
  for (var i = 0; i < items.length; i++) {
    var row = af('Feature Row', 'HORIZONTAL', { gap: 12, ca: 'CENTER' });
    feats.appendChild(row);
    sH(row, 'FILL');
    sV(row, 'HUG');
    var chk = tx('\u2713', FONT_BOLD, 20, solid(theme.checkmark), { name: 'Icon(check)' });
    row.appendChild(chk);
    var lb = tx(items[i], FONT_SEMI, 15, solid(theme.bodyText), { ar: 'HEIGHT' });
    row.appendChild(lb);
    sH(lb, 'FILL');
  }

  // Packages section
  var pkgsWrap = af('Packages Wrap', 'VERTICAL', { pt: 28 });
  cnt.appendChild(pkgsWrap);
  sH(pkgsWrap, 'FILL');
  sV(pkgsWrap, 'HUG');

  var pkgs = af('Packages', 'HORIZONTAL', { gap: 10 });
  pkgsWrap.appendChild(pkgs);
  sH(pkgs, 'FILL');
  sV(pkgs, 'HUG');

  function pkg(name, label, price, period, bd, sel, badge) {
    var c = af(name, 'VERTICAL', {
      gap: 2, pt: badge ? 18 : 14, pb: 14, px: 8,
      fill: solid(sel ? theme.selectedCardBg : theme.cardBg),
      r: 16,
      stroke: solid(sel ? theme.selectedBorder : theme.unselectedBorder),
      sw: 2,
      ca: 'CENTER', ma: 'CENTER'
    });
    if (badge) {
      var bg = af('Badge', 'HORIZONTAL', {
        px: 10, py: 3, fill: solid(theme.badgeBg), r: 20,
        ca: 'CENTER', ma: 'CENTER'
      });
      c.appendChild(bg);
      bg.appendChild(tx('BEST VALUE', FONT_EXTRA, 9, solid(theme.badgeText), { ls: 0.5 }));
    }
    c.appendChild(tx(label, FONT_BOLD, 11, solid(theme.priceNameColor), { ls: 0.5, al: 'CENTER' }));
    c.appendChild(tx(price, FONT_EXTRA, 22, solid(theme.priceLabelColor), { al: 'CENTER' }));
    c.appendChild(tx(period, FONT_REGULAR, 11, solid(theme.pricePeriodColor), { al: 'CENTER' }));
    if (bd) {
      var bdt = tx(bd, FONT_SEMI, 10, solid(theme.priceBreakdown), { al: 'CENTER', lh: 14 });
      c.appendChild(bdt);
      sH(bdt, 'FILL');
    }
    return c;
  }

  var mo = pkg('Package(monthly)', 'MONTHLY', '$2.99', '/month', null, false, false);
  pkgs.appendChild(mo); sH(mo, 'FILL'); sV(mo, 'FILL');

  var yr = pkg('Package(yearly)', 'YEARLY', '$19.99', '/year', '$1.67/mo \u2014 Save 44%', true, true);
  pkgs.appendChild(yr); sH(yr, 'FILL'); sV(yr, 'FILL');

  var lt = pkg('Package(lifetime)', 'LIFETIME', '$49.99', 'one time', 'Pay once, grow forever', false, false);
  pkgs.appendChild(lt); sH(lt, 'FILL'); sV(lt, 'FILL');

  // ── CTA BUTTON ──
  var ctaWrap = af('CTA Wrap', 'VERTICAL', { px: 24, pt: 20 });
  root.appendChild(ctaWrap);
  sH(ctaWrap, 'FILL');
  sV(ctaWrap, 'HUG');

  var cta = af('Purchase Button', 'HORIZONTAL', {
    py: 16, fill: solid(theme.ctaBg), r: 12,
    ma: 'CENTER', ca: 'CENTER'
  });
  ctaWrap.appendChild(cta);
  sH(cta, 'FILL');
  sV(cta, 'HUG');
  cta.appendChild(tx('Start Growing Pro', FONT_EXTRA, 17, solid(theme.ctaText), { ls: 0.3, al: 'CENTER' }));

  // ── FLEXIBLE SPACER (pushes footer to bottom) ──
  var spacer = af('Spacer', 'VERTICAL', {});
  root.appendChild(spacer);
  sH(spacer, 'FILL');
  sV(spacer, 'FILL');

  // ── FOOTER ──
  var ft = af('Footer', 'HORIZONTAL', {
    gap: 6, pt: 16, pb: 34,
    ma: 'CENTER', ca: 'CENTER'
  });
  root.appendChild(ft);
  sH(ft, 'FILL');
  sV(ft, 'HUG');

  // Restore button with RC naming
  var rb = af('Button(action=restore_purchases)', 'HORIZONTAL', { ma: 'CENTER', ca: 'CENTER' });
  ft.appendChild(rb);
  rb.appendChild(tx('Restore Purchases', FONT_SEMI, 12, solid(theme.footerText)));

  ft.appendChild(tx('\u00B7', FONT_REGULAR, 12, solid(theme.footerSep)));
  ft.appendChild(tx('Terms', FONT_SEMI, 12, solid(theme.footerText)));
  ft.appendChild(tx('\u00B7', FONT_REGULAR, 12, solid(theme.footerSep)));
  ft.appendChild(tx('Privacy', FONT_SEMI, 12, solid(theme.footerText)));

  return root;
}

async function main() {
  console.log('Furrow Paywall v4 — RC-compatible');
  await loadFonts();
  var light = buildPaywall(LIGHT);
  light.x = 0; light.y = 0;
  var dark = buildPaywall(DARK);
  dark.x = 440; dark.y = 0;
  figma.viewport.scrollAndZoomIntoView([light, dark]);
  console.log('Done! Both paywalls generated.');
  figma.closePlugin();
}
main();
"""

# Replace placeholders
js_output = JS_TEMPLATE.replace('__ICON_B64__', b64)
js_output = js_output.replace('__HERO_B64__', hero_b64)

with open('C:/Projects/GrowLog/store/paywall-template/code.js', 'w', encoding='utf-8') as f:
    f.write(js_output)

print(f"Written code.js ({len(js_output)} bytes, {len(js_output)//1024}KB)")
