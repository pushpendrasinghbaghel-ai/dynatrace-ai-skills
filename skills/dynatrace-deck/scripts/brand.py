#!/usr/bin/env python3
"""brand.py ΓÇö apply Dynatrace branding to a deck built with dtdeck, and slim it.

    python3 brand.py raw.pptx --out ~/Desktop/Deck.pptx \
        --footer "Acme Corp  ┬╖  Platform Modernization"

What it does, and why each step exists:

1. Adds the official Dynatrace logo top-right on the layout the slides use.
   The logo is copied from the corporate template's own Title Slide, so it is
   the real brand asset rather than a re-drawn approximation. Putting it on the
   layout (not each slide) means it stays put if slides are added later.

2. Adds a footer bottom-left, alongside the template's own slide numbers.

3. Forces the layout backdrop to solid black. Some corporate layouts carry a
   navy gradient; against PowerPoint's black editing canvas that reads as a
   band above the slide, and it fights the dark panel styling.

4. Deletes every layout the deck does not use. Corporate templates ship 60+
   layouts, several customised for named accounts ΓÇö those carry other
   customers' logos and names. Dropping them removes that exposure and takes
   the file from ~14 MB to ~2 MB once orphaned media is swept.

Renders are the only reliable check: run the output through soffice/pdftoppm
and look at the images before sending it anywhere.
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

from lxml import etree

P = '{http://schemas.openxmlformats.org/presentationml/2006/main}'
A = '{http://schemas.openxmlformats.org/drawingml/2006/main}'
R = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}'
RELNS = 'http://schemas.openxmlformats.org/package/2006/relationships'
IMGTYPE = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image'

RIGHT_EDGE_EMU = int(12.59 * 914400)
LOGO_TOP_EMU = int(0.24 * 914400)
EMU = 914400


def _write(tree_or_el, path):
    et = tree_or_el if hasattr(tree_or_el, 'write') else etree.ElementTree(tree_or_el)
    et.write(path, xml_declaration=True, encoding='UTF-8', standalone=True)


def _layout_in_use(root):
    used = set()
    for r in glob.glob(os.path.join(root, 'ppt/slides/_rels/*.rels')):
        for t in re.findall(r'Target="([^"]+slideLayout\d+\.xml)"', open(r).read()):
            used.add(os.path.basename(t))
    if len(used) != 1:
        raise SystemExit('Expected exactly one layout in use, found: %s' % (used or 'none'))
    return used.pop()


def _find_logo(root):
    """Find the widest wordmark-shaped picture across the template's layouts.

    Returns (pic_element, {rId: target}) or (None, None). The Dynatrace
    wordmark lives on the Title Slide layout at ~2.8in wide.
    """
    best = None
    for lay in sorted(glob.glob(os.path.join(root, 'ppt/slideLayouts/slideLayout*.xml'))):
        rels = os.path.join(os.path.dirname(lay), '_rels', os.path.basename(lay) + '.rels')
        if not os.path.exists(rels):
            continue
        tgt = {r.get('Id'): r.get('Target') for r in etree.parse(rels).getroot()}
        for pic in etree.parse(lay).getroot().iter(P + 'pic'):
            xf = pic.find(P + 'spPr/' + A + 'xfrm')
            if xf is None:
                continue
            ext = xf.find(A + 'ext')
            w, h = int(ext.get('cx')) / EMU, int(ext.get('cy')) / EMU
            if h <= 0 or not (2.0 < w / h < 10) or not (1.5 < w < 4.5):
                continue
            embeds = [b.get(R + 'embed') for b in pic.iter()
                      if b.get(R + 'embed') is not None]
            if not embeds:
                continue
            if best is None or w > best[0]:
                best = (w, pic, {e: tgt[e] for e in embeds if e in tgt})
    if best is None:
        return None, None
    return best[1], best[2]


def brand(src, out, footer=None, black_bg=True, keep_gradient=False):
    work = tempfile.mkdtemp(prefix='dtbrand_')
    subprocess.run(['unzip', '-q', src, '-d', work], check=True)

    keep = _layout_in_use(work)
    lay_path = os.path.join(work, 'ppt/slideLayouts', keep)
    name = re.search(r'name="([^"]+)"', open(lay_path).read()).group(1)
    print('layout in use: %s (%s)' % (keep, name))

    tree = etree.parse(lay_path)
    spTree = tree.getroot().find(P + 'cSld').find(P + 'spTree')

    rels_path = os.path.join(work, 'ppt/slideLayouts/_rels', keep + '.rels')
    rels = etree.parse(rels_path).getroot()

    # ---- 1. logo, top-right -------------------------------------------------
    logo, logo_rels = _find_logo(work)
    if logo is None:
        print('WARNING: no wordmark found in the template; logo not added')
    else:
        existing = {r.get('Id') for r in rels}
        n = 1
        xml = etree.tostring(logo).decode()
        for old, target in logo_rels.items():
            while ('rId%d' % n) in existing:
                n += 1
            new = 'rId%d' % n
            existing.add(new)
            rel = etree.SubElement(rels, '{%s}Relationship' % RELNS)
            rel.set('Id', new)
            rel.set('Type', IMGTYPE)
            rel.set('Target', target)
            xml = xml.replace('r:embed="%s"' % old, 'r:embed="%s"' % new)
        el = etree.fromstring(xml)
        xf = el.find(P + 'spPr/' + A + 'xfrm')
        off, ext = xf.find(A + 'off'), xf.find(A + 'ext')
        off.set('x', str(RIGHT_EDGE_EMU - int(ext.get('cx'))))
        off.set('y', str(LOGO_TOP_EMU))
        spTree.append(el)
        _write(rels, rels_path)
        print('logo placed top-right (%.2f in wide)' % (int(ext.get('cx')) / EMU))

    # ---- 2. backdrop --------------------------------------------------------
    if black_bg:
        for sp in list(spTree):
            if sp.tag != P + 'sp':
                continue
            nv = sp.find('.//' + P + 'cNvPr')
            nm = (nv.get('name') or '') if nv is not None else ''
            if not nm.startswith('Rectangle'):
                continue
            spPr = sp.find(P + 'spPr')
            xf = spPr.find(A + 'xfrm') if spPr is not None else None
            if xf is None:
                continue
            ext = xf.find(A + 'ext')
            if ext is not None and int(ext.get('cx')) > 12 * EMU:
                for f in spPr.findall(A + 'solidFill') + spPr.findall(A + 'gradFill'):
                    spPr.remove(f)
                fill = etree.fromstring(
                    '<a:solidFill xmlns:a="%s"><a:srgbClr val="000000"/></a:solidFill>'
                    % A.strip('{}'))
                geom = spPr.find(A + 'prstGeom')
                (geom if geom is not None else xf).addnext(fill)
                print('  backdrop %s -> #000000' % nm)
            elif not keep_gradient:
                spTree.remove(sp)
                print('  removed gradient overlay %s' % nm)

    # ---- 3. footer ----------------------------------------------------------
    if footer:
        replaced = False
        for sp in spTree.iter(P + 'sp'):
            ts = [t for t in sp.iter(A + 't')]
            if not ts:
                continue
            joined = ''.join(t.text or '' for t in ts)
            if len(joined) > 12 and 'ΓÇ╣#ΓÇ║' not in joined:
                ts[0].text = footer
                for t in ts[1:]:
                    t.text = ''
                replaced = True
                break
        if not replaced:
            box = etree.fromstring(
                '<p:sp %s><p:nvSpPr><p:cNvPr id="900" name="footer"/>'
                '<p:cNvSpPr txBox="1"/><p:nvPr userDrawn="1"/></p:nvSpPr>'
                '<p:spPr><a:xfrm><a:off x="%d" y="%d"/><a:ext cx="%d" cy="%d"/></a:xfrm>'
                '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>'
                '<p:txBody><a:bodyPr wrap="square" lIns="0" tIns="0" rIns="0" bIns="0"/>'
                '<a:lstStyle/><a:p><a:r><a:rPr lang="en-US" sz="800">'
                '<a:solidFill><a:srgbClr val="6F84AE"/></a:solidFill>'
                '<a:latin typeface="DTFlow-Light"/></a:rPr><a:t>%s</a:t></a:r></a:p>'
                '</p:txBody></p:sp>'
                % (nsdecls_pptx(), int(0.25 * EMU), int(7.21 * EMU),
                   int(6.0 * EMU), int(0.25 * EMU),
                   footer.replace('&', '&amp;').replace('<', '&lt;')))
            spTree.append(box)
        print('footer -> %s' % footer)

    _write(tree, lay_path)

    # ---- 4. drop unused layouts --------------------------------------------
    mrels_path = os.path.join(work, 'ppt/slideMasters/_rels/slideMaster1.xml.rels')
    mrels = etree.parse(mrels_path).getroot()
    drop = []
    for rel in list(mrels):
        tg = rel.get('Target')
        if 'slideLayout' in tg and os.path.basename(tg) != keep:
            drop.append(rel.get('Id'))
            mrels.remove(rel)
    _write(mrels, mrels_path)

    mpath = os.path.join(work, 'ppt/slideMasters/slideMaster1.xml')
    mt = etree.parse(mpath)
    lst = mt.getroot().find(P + 'sldLayoutIdLst')
    for e in list(lst):
        if e.get(R + 'id') in drop:
            lst.remove(e)
    _write(mt, mpath)

    for f in glob.glob(os.path.join(work, 'ppt/slideLayouts/slideLayout*.xml')):
        if os.path.basename(f) != keep:
            os.remove(f)
            rr = os.path.join(os.path.dirname(f), '_rels', os.path.basename(f) + '.rels')
            if os.path.exists(rr):
                os.remove(rr)
    print('dropped %d unused layouts' % len(drop))

    ctp = os.path.join(work, '[Content_Types].xml')
    ct = etree.parse(ctp)
    for o in list(ct.getroot()):
        pn = o.get('PartName') or ''
        if 'slideLayout' in pn and not pn.endswith('/' + keep):
            ct.getroot().remove(o)
    _write(ct, ctp)

    # ---- 5. orphan media ----------------------------------------------------
    used = set()
    for r in glob.glob(os.path.join(work, '**/_rels/*.rels'), recursive=True):
        base = os.path.dirname(os.path.dirname(r))
        for tg in re.findall(r'Target="([^"]+)"', open(r, encoding='utf8').read()):
            if 'media/' in tg:
                used.add(os.path.normpath(os.path.join(base, tg)))
    for m in glob.glob(os.path.join(work, 'ppt/media/*')):
        if os.path.normpath(m) not in used:
            os.remove(m)

    out = os.path.abspath(os.path.expanduser(out))
    if os.path.exists(out):
        os.remove(out)
    subprocess.run(['zip', '-q', '-r', '-X', out, '.'], cwd=work, check=True)
    shutil.rmtree(work, ignore_errors=True)
    print('wrote %s  (%.2f MB)' % (out, os.path.getsize(out) / 1e6))

    if len(out) > 200:
        print('\nWARNING: path is %d chars. PowerPoint refuses files whose path '
              'approaches 259 characters. Save somewhere shorter.' % len(out))
    return out


def nsdecls_pptx():
    return ('xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"')


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('src')
    ap.add_argument('--out', required=True)
    ap.add_argument('--footer', default=None,
                    help='Bottom-left footer, e.g. "Acme Corp  ┬╖  Solution Overview"')
    ap.add_argument('--keep-gradient', action='store_true',
                    help='Keep the layout gradient instead of solid black')
    a = ap.parse_args()
    if not os.path.exists(a.src):
        sys.exit('No such file: %s' % a.src)
    brand(a.src, a.out, a.footer, black_bg=True, keep_gradient=a.keep_gradient)


if __name__ == '__main__':
    main()
