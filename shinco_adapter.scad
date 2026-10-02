// ============================================================
// SHINCO - adapter: prostokątny wylot zimnego powietrza -> rura Ø150
// Dzielony na 2 połówki (całość nie mieści się na stole Bambu)
// ------------------------------------------------------------
// Wymiary odczytane ze zdjęć z miarką - ZWERYFIKUJ wydrukiem testowym!
// ============================================================

/* ================= PARAMETRY ================= */

// -- Otwór kratki (wewnętrzny prostokąt z zaokrąglonymi rogami) --
pw   = 255;   // szerokość otworu kratki, mm
ph   = 145;   // wysokość otworu kratki, mm
pr   = 30;    // promień zaokrąglenia rogów otworu, mm
p_skirt = 60;

// -- Kołnierz (siada na białej ramce/bezelu wokół kratki, ~18 mm szer.) --
fb   = 6;    // szerokość kołnierza, mm
ft   = 14;   // grubość kołnierza, mm
f_wystaje = 4;

// -- Rura --
dd   = 150;   // ŚREDNICA WEWNĘTRZNA króćca, mm  <- zmierz swoją rurę!
sl   = 45;    // długość króćca, mm

// -- Przejście --
pd   = 85;    // długość przejścia prostokąt->okrąg, mm
wall = 2.5;   // grubość ścianki, mm

// -- Złącze dwóch połówek --
jw   = 9;     // ile płyta złącza wystaje poza powłokę, mm
jt   = 4;     // grubość płyty złącza (na połówkę), mm
sd   = 3.3;   // średnica otworów pod śruby M3, mm

$fn = 96;

/* ================= GEOMETRIA ================= */

module rr(w, h, r) {
    hull() for (x=[-1,1], y=[-1,1])
        translate([x*(w/2-r), y*(h/2-r)]) circle(r=r);
}

// w, h, r — jak w rr(), ale r dotyczy tylko GÓRNYCH rogów
// skirt — o ile profil schodzi poniżej dolnej krawędzi
// sw    — szerokość dolnego prostokąta (0 = taka sama jak w)
module rr_foot(w, h, r, skirt=0,wysokosc_nad_wylot=0, sw=0) {
    ww = (sw > 0) ? sw : w;
    hull() {
        translate([-ww/2, h/2 + wysokosc_nad_wylot]) square([ww, 0.01]);   // 2 okręgi: góra
        translate([-ww/2, -h/2-skirt]) square([ww, 0.01]);          // 1 prostokąt: dół
    }
}
// Bryła zewnętrzna, opcjonalnie rozdmuchana o `e` mm na zewnątrz
module outer_solid(e=0) {
    union() {
        // kołnierz
        difference(){
            linear_extrude(ft) rr_foot(pw+2*fb+2*e, ph+2*fb+2*e, pr+fb+e, skirt=p_skirt,wysokosc_nad_wylot=20, sw=0);
            union(){
                translate([0,-ph/2,-0.5]) linear_extrude(f_wystaje + 0.5) square([pw, ph+50], center=true);
                translate([0,-100, 2*fb]) linear_extrude(3) square([2*pw, 5], center=true);
                translate([0, 90, 2*fb]) linear_extrude(3) square([2*pw, 5], center=true);
            }
        }
        // przejście
        translate([0,0,ft]) hull() {
            linear_extrude(0.02) rr(pw+2*wall+2*e, ph+2*wall+2*e, pr+wall+e);
            translate([0,0,pd]) linear_extrude(0.02) circle(d=dd+2*wall+2*e);
        }
        // króciec + rowek pod opaskę
        translate([0,0,ft+pd-0.01]) cylinder(h=sl+0.01, d=dd+2*wall+2*e);
        translate([0,0,ft+pd+sl*0.55]) cylinder(h=4, d=dd+2*wall+3+2*e);
    }
}

// Kanał powietrza (do odjęcia)
module inner_void() {
    union() {
        translate([0,0,-1]) linear_extrude(ft+1.01) rr(pw, ph, pr);
        translate([0,0,ft]) hull() {
            linear_extrude(0.02) rr(pw, ph, pr);
            translate([0,0,pd]) linear_extrude(0.02) circle(d=dd);
        }
        translate([0,0,ft+pd-0.01]) cylinder(h=sl+2, d=dd);
    }
}

module shell() { difference() { outer_solid(0); inner_void(); } }

// Płyta złącza po jednej stronie płaszczyzny cięcia x=0
module joint_plate(side) {
    difference() {
        intersection() {
            outer_solid(jw);
            translate([side>0 ? 0 : -jt, -400, -1]) cube([jt, 800, 400]);
        }
        inner_void();
    }
}

// Otwory pod śruby M3 (oś X), 3 poziomy x 2 strony
screw_pts = [
    [63, ft+12],
    [71, ft+45],
    [81, ft+pd+20]
];

module screw_holes() {
    for (p = screw_pts, s = [-1,1])
        translate([-20, s*p[0], p[1]]) rotate([0,90,0])
            cylinder(h=40, d=sd);
}

module half(side) {
    difference() {
        union() {
            intersection() {
                shell();
                translate([side>0 ? 0 : -400, -400, -1]) cube([400, 800, 400]);
            }
            joint_plate(side);
        }
        screw_holes();
    }
}

// Pierścień testowy: sam kołnierz + 12 mm przejścia (szybki wydruk kontrolny)
module test_ring(side) {
    intersection() {
        half(side);
        translate([-400,-400,-1]) cube([800,800,ft+12+1]);
    }
}

/* ================= WYBÓR CZĘŚCI ================= */
// zmień PART: "left" | "right" | "test_left" | "test_right" | "assembled"
PART = "assembled";

if (PART == "left")       half(-1);
else if (PART == "right") half(1);
else if (PART == "test_left")  test_ring(-1);
else if (PART == "test_right") test_ring(1);
else { half(-1); half(1); }
