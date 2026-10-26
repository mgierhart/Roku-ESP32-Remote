// Roku ESP32 Remote - handheld case
// Parametric OpenSCAD model. Units: mm.
//
// Parts (set PART below, or pass -D 'PART="lid"' on the command line):
//   "bottom"   - bottom shell (print floor-down)
//   "lid"      - faceplate (exported face-down, ready to print)
//   "caps"     - all 18 button caps + 2 spares (print as-is, flat side down)
//   "coupon"   - small fit test: one hole of each size + one screw boss
//   "assembly" - preview only, not for printing
//
// Hardware it is designed around:
//   - 6x6 mm tactile switches, 4-pin through-hole, 7 mm total height (6x6x7)
//   - 5 x 7 cm perfboard, 2.54 mm pitch, 18 x 24 holes, 1.6 mm thick
//   - 38-pin ESP32-WROOM-32 dev board, USB-C, about 55 x 28.5 mm
//   - 4x M2 x 10 mm self-tapping screws
//
// Every button position comes from the BUTTONS table and sits on the
// perfboard's 2.54 mm grid, so the switches drop straight into the board.

PART = "assembly";

$fn = 48;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

pitch      = 2.54;
// Perfboard
pb_w       = 50;      // width  (x)
pb_l       = 70;      // length (y)
pb_t       = 1.6;
pb_holes_x = 18;
pb_holes_y = 24;
pb_clear   = 0.3;     // pocket clearance around the board

// Switch: 6x6 body 3.5 tall, round stem, total height above board
sw_h       = 7.0;
sw_body_h  = 3.5;

// Shell
wall       = 2.0;
floor_t    = 2.0;
lid_t      = 2.0;
corner_r   = 6;
under_pb   = 5.8;     // room under the perfboard for switch legs and wires

// Caps
cap_gap    = 0.6;     // gap between cap flange and lid underside (rattle room)
sock_d     = 4.8;     // socket over the ~3.5 mm stem; oversize absorbs misalignment
sock_depth = 1.8;
flange_t   = 1.0;
flange_out = 0.8;     // flange overhang past the cap body
cap_r      = 2.5;     // cap corner radius
cap_proud  = 2.5;     // how far caps stand above the faceplate
power_proud= 1.0;     // power sits lower so it's hard to bump
hole_clear = 0.3;     // per side, cap body to faceplate hole
engrave    = 0.6;     // label depth

// ESP32 bay
esp_len    = 58;      // bay length; board's USB end sits against the end wall
esp_w      = 28.5;    // board width (rails sit just outside this)
usb_slot_w = 14;      // opening for the USB-C plug's overmold
usb_slot_h = 9;

// Screws (M2 self-tapping)
scr_clear  = 2.4;
scr_pilot  = 1.7;
scr_head_d = 4.6;
boss_d     = 6;

// ---------------------------------------------------------------------------
// Derived heights (z = 0 is the outside bottom of the case)
// ---------------------------------------------------------------------------

z_floor    = floor_t;
z_pb_bot   = z_floor + under_pb;
z_pb_top   = z_pb_bot + pb_t;
z_stem_top = z_pb_top + sw_h;
z_cap_bot  = z_stem_top - sock_depth;
z_flange_t = z_cap_bot + flange_t;
z_lid_bot  = z_flange_t + cap_gap;
z_lid_top  = z_lid_bot + lid_t;
z_boss_split = z_lid_bot - 4.2;     // where bottom post meets lid boss

// ---------------------------------------------------------------------------
// Layout in plan view. x = 0 is the remote's centerline, y = 0 the USB end.
// ---------------------------------------------------------------------------

y_bay0     = wall;                         // inner face of USB end wall
y_bay1     = y_bay0 + esp_len;
y_pb0      = y_bay1 + 2.3;                 // perfboard bottom edge
y_pb1      = y_pb0 + pb_l;                 // perfboard top edge
y_scr_top  = y_pb1 + 1.3 + 1.2 + boss_d/2 + 0.6;
L          = y_scr_top + boss_d/2 + 0.8 + wall;

// First hole's offset from the board edge (the 18 x 24 grid is centered)
pb_ox      = (pb_w - (pb_holes_x - 1) * pitch) / 2;
pb_oy      = (pb_l - (pb_holes_y - 1) * pitch) / 2;

// Board x offset chosen so hole column 9 lands on the centerline
x_pb0      = -(pb_ox + 9 * pitch);
x_pb1      = x_pb0 + pb_w;

inner_half = max(-x_pb0, x_pb1) + pb_clear;
W          = 2 * (inner_half + wall);

// Hole (i, j) -> plan position. j counts down from the top row of holes.
function hole_x(i) = x_pb0 + pb_ox + i * pitch;
function hole_y(j) = y_pb1 - pb_oy - j * pitch;

// ---------------------------------------------------------------------------
// Buttons: [label, icon, i_center, j_center, cap_w, cap_h]
// Switch legs go in holes (i-1, j-1.5) (i+1, j-1.5) (i-1, j+1.5) (i+1, j+1.5).
// GPIO numbers match roku_remote.ino.
// ---------------------------------------------------------------------------

WIDE = 10.5;  // caps in 3-across rows (12.7 mm pitch)
NARR = 8.0;   // caps in 4-across rows (10.16 mm pitch)
CAPH = 8.0;   // all rows are 10.16 mm apart

BUTTONS = [
  // row 1
  ["Back",   "back",   4,  1.5, WIDE, CAPH],  // GPIO 25
  ["Power",  "power",  9,  1.5, WIDE, CAPH],  // GPIO 2
  ["Home",   "home",  14,  1.5, WIDE, CAPH],  // GPIO 26
  // row 2
  ["Info",   "info",   4,  5.5, WIDE, CAPH],  // GPIO 19
  ["Up",     "up",     9,  5.5, WIDE, CAPH],  // GPIO 23
  ["Vol+",   "plus",  14,  5.5, WIDE, CAPH],  // GPIO 14
  // row 3
  ["Left",   "left",   4,  9.5, WIDE, CAPH],  // GPIO 4
  ["OK",     "ok",     9,  9.5, WIDE, CAPH],  // GPIO 15
  ["Right",  "right", 14,  9.5, WIDE, CAPH],  // GPIO 5
  // row 4 (left slot left free for a future button, e.g. Mute)
  ["Down",   "down",   9, 13.5, WIDE, CAPH],  // GPIO 21
  ["Vol-",   "minus", 14, 13.5, WIDE, CAPH],  // GPIO 12
  // row 5
  ["Rev",    "rev",    4, 17.5, WIDE, CAPH],  // GPIO 33
  ["Play",   "play",   9, 17.5, WIDE, CAPH],  // GPIO 32
  ["Fwd",    "fwd",   14, 17.5, WIDE, CAPH],  // GPIO 27
  // row 6
  ["HDMI 1", "1",      3, 21.5, NARR, CAPH],  // GPIO 13
  ["HDMI 2", "2",      7, 21.5, NARR, CAPH],  // GPIO 16
  ["HDMI 3", "3",     11, 21.5, NARR, CAPH],  // GPIO 17
  ["HDMI 4", "4",     15, 21.5, NARR, CAPH],  // GPIO 18
];

function bx(b) = hole_x(b[2]);
function by(b) = hole_y(b[3]);

// HDMI label sits between the input row and the ESP32 bay
hdmi_label_y = (y_pb0 + (hole_y(21.5) - CAPH/2 - flange_out)) / 2;

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------

module rrect(w, h, r) {
  r2 = min(r, w/2 - 0.01, h/2 - 0.01);
  offset(r = r2) square([w - 2*r2, h - 2*r2], center = true);
}

module outline(inset = 0) {
  rrect(W - 2*inset, L - 2*inset, max(corner_r - inset, 0.5));
}

// Plan-view outline placed in model coordinates
module outline_at(inset = 0) {
  translate([0, L/2]) outline(inset);
}

// ---------------------------------------------------------------------------
// Icons (2D, roughly 6 x 5 mm, centered). Strokes are >= 1.0 mm so they
// survive a 0.4 mm nozzle.
// ---------------------------------------------------------------------------

module tri(dir = 0, s = 4.6) {          // solid triangle pointing +x, rotated
  rotate(dir) polygon([[ s*0.5, 0], [-s*0.4, s*0.5], [-s*0.4, -s*0.5]]);
}

module bar(len, w = 1.1) { square([len, w], center = true); }

module icon(name) {
  if      (name == "up")    tri(90);
  else if (name == "down")  tri(-90);
  else if (name == "left")  tri(180);
  else if (name == "right") tri(0);
  else if (name == "plus")  { bar(5); rotate(90) bar(5); }
  else if (name == "minus") bar(5);
  else if (name == "play")  {
    translate([-1.3, 0]) tri(0, 4.0);
    translate([1.5, 0]) { translate([-0.6, 0]) square([0.9, 3.6], center = true);
                          translate([ 0.8, 0]) square([0.9, 3.6], center = true); }
  }
  else if (name == "fwd")   { translate([-1.2, 0]) tri(0, 3.6); translate([1.3, 0]) tri(0, 3.6); }
  else if (name == "rev")   { translate([ 1.2, 0]) tri(180, 3.6); translate([-1.3, 0]) tri(180, 3.6); }
  else if (name == "home")  {
    polygon([[0, 2.7], [-2.9, 0.2], [-2.1, 0.2], [-2.1, -2.5], [2.1, -2.5], [2.1, 0.2], [2.9, 0.2]]);
  }
  else if (name == "power") {
    difference() {
      circle(d = 5.2);
      circle(d = 3.0);
      translate([0, 2]) square([2.4, 4], center = true);   // gap at top of ring
    }
    translate([0, 1.1]) square([1.0, 3.2], center = true);  // stroke through gap
  }
  else if (name == "info")  {                                // Roku "*" key
    for (a = [0, 60, 120]) rotate(a + 90) bar(5.2, 1.1);
  }
  else if (name == "back")  {                                // hooked arrow
    difference() {
      translate([0.6, 0.3]) circle(d = 4.6);
      translate([0.6, 0.3]) circle(d = 2.4);
      translate([-2.5, -3]) square([3.1, 3.3]);              // open lower-left
    }
    translate([-1.9, -1.6]) rotate(180) tri(0, 2.6);         // arrow head
    translate([-0.4, -1.6]) square([1.2, 1.1], center = true);
  }
  else if (name == "ok")    text("OK", size = 3.6, font = "Liberation Sans:style=Bold",
                                 halign = "center", valign = "center");
  else                      text(name, size = 4.6, font = "Liberation Sans:style=Bold",
                                 halign = "center", valign = "center");
}

// ---------------------------------------------------------------------------
// Caps (modeled at the origin, bottom at z = 0)
// ---------------------------------------------------------------------------

module cap(b) {
  w = b[4]; h = b[5];
  proud = (b[1] == "power") ? power_proud : cap_proud;
  body_h = (z_lid_top + proud) - z_cap_bot - flange_t;
  difference() {
    union() {
      linear_extrude(flange_t) rrect(w + 2*flange_out, h + 2*flange_out, cap_r + flange_out);
      translate([0, 0, flange_t]) linear_extrude(body_h) rrect(w, h, cap_r);
    }
    translate([0, 0, -0.01]) cylinder(d = sock_d, h = sock_depth + 0.01);
    translate([0, 0, flange_t + body_h - engrave]) linear_extrude(engrave + 0.01) icon(b[1]);
  }
}

module caps_plate() {
  cols = 5;
  sp = 15;
  spares = [["spare", "", 0, 0, WIDE, CAPH], ["spare", "", 0, 0, NARR, CAPH]];
  all = concat(BUTTONS, spares);
  for (k = [0 : len(all) - 1])
    translate([(k % cols) * sp, -floor(k / cols) * sp, 0]) cap(all[k]);
}

// ---------------------------------------------------------------------------
// Bottom shell
// ---------------------------------------------------------------------------

scr_pos = [
  [-20.5, y_bay0 + esp_len * 0.55], [20.5, y_bay0 + esp_len * 0.55],
  [-15, y_scr_top], [15, y_scr_top],
];

module usb_slot() {
  // through the USB end wall, centered on the ESP32's USB-C port
  usb_z = z_floor + 8.5 + 1.6 + 1.6;   // pins on floor -> PCB -> port center
  translate([-usb_slot_w/2, -1, usb_z - usb_slot_h/2])
    cube([usb_slot_w, wall + 2, 30]);
}

module bottom_shell() {
  difference() {
    union() {
      // floor + walls with a 1 mm chamfer on the bottom edge
      hull() {
        linear_extrude(0.01) outline_at(1);
        translate([0, 0, 1]) linear_extrude(0.01) outline_at(0);
      }
      translate([0, 0, 1]) linear_extrude(z_lid_bot - 1)
        difference() { outline_at(0); outline_at(wall); }
      linear_extrude(z_floor) outline_at(0.5);

      // perfboard corner posts
      for (cx = [x_pb0 + 2, x_pb1 - 2], cy = [y_pb0 + 2, y_pb1 - 2])
        translate([cx - 2, cy - 2, 0]) cube([4, 4, z_pb_bot]);

      // perfboard locating ribs: right side, top edge, and stops at the bay side
      translate([x_pb1 + pb_clear, y_pb0 + 8, 0]) cube([inner_half - x_pb1 - pb_clear + 0.1, pb_l - 16, z_pb_top]);
      translate([x_pb0 + 8, y_pb1 + pb_clear, 0]) cube([pb_w - 16, 1.2, z_pb_top]);
      for (cx = [x_pb0 + 1, x_pb1 - 5])
        translate([cx, y_pb0 - pb_clear - 1.2, 0]) cube([4, 1.2, z_pb_top]);

      // ESP32 rails (keep the board's pin rows from sliding sideways)
      for (s = [-1, 1])
        translate([s > 0 ? esp_w/2 + 0.4 : -esp_w/2 - 0.4 - 1.2, y_bay0 + 4, 0])
          cube([1.2, esp_len - 10, z_floor + 4]);

      // screw posts
      for (p = scr_pos) translate([p[0], p[1], 0]) cylinder(d = boss_d, h = z_boss_split);
    }
    // screw clearance + counterbore from below
    for (p = scr_pos) translate([p[0], p[1], -0.01]) {
      cylinder(d = scr_clear, h = z_boss_split + 1);
      // head sits 6 mm up; a 10 mm screw then bites ~3.8 mm into the lid boss
      // and stops ~2 mm short of the lid face
      cylinder(d = scr_head_d, h = z_boss_split - 6);
    }
    usb_slot();
  }
}

// ---------------------------------------------------------------------------
// Lid / faceplate (modeled in assembled position)
// ---------------------------------------------------------------------------

module lid() {
  difference() {
    union() {
      // plate with a 1 mm chamfer on the top edge
      translate([0, 0, z_lid_bot]) linear_extrude(lid_t - 1) outline_at(0);
      hull() {
        translate([0, 0, z_lid_top - 1]) linear_extrude(0.01) outline_at(0);
        translate([0, 0, z_lid_top - 0.01]) linear_extrude(0.01) outline_at(1);
      }
      // locating lip that drops inside the walls
      translate([0, 0, z_lid_bot - 1.5]) linear_extrude(1.5)
        difference() { outline_at(wall + 0.25); outline_at(wall + 1.45); }
      // perfboard hold-down posts
      for (cx = [x_pb0 + 1.6, x_pb1 - 1.6], cy = [y_pb0 + 1.6, y_pb1 - 1.6])
        translate([cx - 1.5, cy - 1.5, z_pb_top]) cube([3, 3, z_lid_bot - z_pb_top + 0.01]);
      // screw bosses
      for (p = scr_pos) translate([p[0], p[1], z_boss_split + 0.2]) cylinder(d = boss_d, h = z_lid_bot - z_boss_split);
    }
    // button holes
    for (b = BUTTONS) translate([bx(b), by(b), z_lid_bot - 2])
      linear_extrude(lid_t + 3) rrect(b[4] + 2*hole_clear, b[5] + 2*hole_clear, cap_r + hole_clear);
    // pilot holes
    for (p = scr_pos) translate([p[0], p[1], z_boss_split]) cylinder(d = scr_pilot, h = z_lid_bot - z_boss_split + lid_t - 0.8);
    // "HDMI" label
    translate([0, hdmi_label_y, z_lid_top - engrave]) linear_extrude(engrave + 0.01)
      text("HDMI", size = 3.4, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    usb_slot();
  }
}

// ---------------------------------------------------------------------------
// Fit test coupon: a slice of faceplate with one hole of each size and a boss,
// plus one of each cap. Print this first if you want to check tolerances.
// ---------------------------------------------------------------------------

module coupon() {
  difference() {
    union() {
      linear_extrude(lid_t) rrect(40, 16, 2);
      translate([14, 0, 0]) cylinder(d = boss_d, h = lid_t + 4.2);
    }
    translate([-12, 0, -1]) linear_extrude(lid_t + 2) rrect(WIDE + 2*hole_clear, CAPH + 2*hole_clear, cap_r + hole_clear);
    translate([2, 0, -1]) linear_extrude(lid_t + 2) rrect(NARR + 2*hole_clear, CAPH + 2*hole_clear, cap_r + hole_clear);
    translate([14, 0, 0.8]) cylinder(d = scr_pilot, h = 10);
  }
  translate([-12, -20, 0]) cap(BUTTONS[7]);    // OK
  translate([2, -20, 0]) cap(BUTTONS[14]);     // HDMI 1
}

// ---------------------------------------------------------------------------
// Assembly preview
// ---------------------------------------------------------------------------

module perfboard() {
  color("darkgreen") translate([x_pb0, y_pb0, z_pb_bot]) cube([pb_w, pb_l, pb_t]);
  for (b = BUTTONS) color("dimgray") {
    translate([bx(b) - 3, by(b) - 3, z_pb_top]) cube([6, 6, sw_body_h]);
    translate([bx(b), by(b), z_pb_top]) cylinder(d = 3.5, h = sw_h);
  }
}

module esp32() {
  color("steelblue") translate([-esp_w/2, y_bay0 + 0.3, z_floor + 8.5]) cube([esp_w, 55, 1.6]);
  color("silver") translate([-9, y_bay0 + 30, z_floor + 8.5 + 1.6]) cube([18, 25, 3.1]);
}

module assembly() {
  color("lightgray") bottom_shell();
  perfboard();
  esp32();
  color("white", 0.85) lid();
  for (b = BUTTONS) color("orange") translate([bx(b), by(b), z_cap_bot]) cap(b);
}

// ---------------------------------------------------------------------------

if (PART == "bottom")        bottom_shell();
else if (PART == "lid")      translate([0, 0, z_lid_top]) rotate([180, 0, 0]) lid();
else if (PART == "caps")     caps_plate();
else if (PART == "coupon")   coupon();
else if (PART == "assembly") assembly();

echo(str("Case outer size: ", W, " x ", L, " x ", z_lid_top, " mm"));
