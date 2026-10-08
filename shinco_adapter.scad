// ============================================================
// SHINCO - adapter: prostokątny wylot zimnego powietrza -> rura Ø150
// Dzielony na 2 połówki (całość nie mieści się na stole Bambu)
// ------------------------------------------------------------
// Wymiary odczytane ze zdjęć z miarką - ZWERYFIKUJ wydrukiem testowym!
// ============================================================

/* ================= PARAMETRY ================= */

// -- Otwór kratki (wewnętrzny prostokąt z zaokrąglonymi rogami) --
pw   = 246;   // szerokość otworu kratki, mm
ph   = 145;   // wysokość otworu kratki, mm
pr   = 30;    // promień zaokrąglenia rogów otworu, mm
p_wystaje_ponizej_wylotu = 60;
p_wysokosc_nad_wylot=23;

// -- Kołnierz (siada na białej ramce/bezelu wokół kratki, ~18 mm szer.) --
fb   = 20;    // szerokość kołnierza, mm
ft   = 10;   // grubość kołnierza, mm
f_wystaje = 4;

// -- Rura --
dd   = 150;   // ŚREDNICA WEWNĘTRZNA króćca, mm  <- zmierz swoją rurę!
sl   = 45;    // długość króćca, mm

// -- Przejście --
pd   = 30;    // długość przejścia prostokąt->okrąg, mm
wall = 3;   // grubość ścianki, mm

// -- Złącze dwóch połówek --
jw   = 0;     // ile płyta złącza wystaje poza powłokę, mm
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
        translate([-ww/2, h/2 + wysokosc_nad_wylot]) square([ww, 0.01]);
        translate([-ww/2, -h/2-skirt]) square([ww, 0.01]);       
    }
}

module rr_fazowanie(w, h, r, skirt=0,wysokosc_nad_wylot=0) {
    
    hull(){
        translate([0,0,-0.1])linear_extrude(0.02) hull() {
            for (x=[-1,1]) translate([x*(w/2-r), h/2-r]) circle(r=r);
            translate([0, -h/2-skirt - 15])  square([w, 0.01], center=true);
        }
        
        translate([0,0,3])linear_extrude(0.02) hull() {
            for (x=[-1,1]) translate([x*(w/2-r), h/2-r]) circle(r=r);
            translate([0, -h/2-skirt - 15])  square([w, 0.01], center=true);
        }
        translate([0,0,6])linear_extrude(0.02) hull() { 
            for (x=[-1,1]) translate([x*(w/2-r - 3), h/2-r -3]) circle(r=r - 3);
            translate([0, -h/2-skirt-15]) square([w - 6, 0.01], center=true);        
        }
    }
}

module heblowanie_na_gorze(w,h, wysokosc_hebla, o_ile_zheblowac, r){
    hull() {
        translate([0, h + h, -0.1 + o_ile_zheblowac]) linear_extrude(0.02) square([w, 2*h], center=true);
        translate([0, h+h-wysokosc_hebla, -0.1]) linear_extrude(0.02) square([w, h*2], center=true);
        translate([0, h+h ,-0.1 + o_ile_zheblowac]) linear_extrude(0.02) square([w, 2*h], center=true);          
    }
}

module bryla_klimatyzatora_glowna(w,r){
    linear_extrude(500) rr(w+2*r,w+2*r,r);
}
// Bryła zewnętrzna, opcjonalnie rozdmuchana o `e` mm na zewnątrz
module outer_solid(e=0) {
    union() {
        // kołnierz
        difference(){
            difference(){
                difference(){
                    linear_extrude(ft) rr_foot(pw+2*fb+2*e, ph+2*fb+2*e, pr+fb+e, skirt=p_wystaje_ponizej_wylotu,wysokosc_nad_wylot=p_wysokosc_nad_wylot, sw=0);
                    union(){
                        translate([0,-ph/2,-0.5]) linear_extrude(f_wystaje + 0.5) square([pw, ph+50], center=true);
                        translate([0,-100, ft - 3]) linear_extrude(4) square([2*pw, 5], center=true);
                        translate([0, 103, ft - 3]) linear_extrude(4) square([2*pw, 5], center=true);
                    }
                }
                rr_fazowanie(pw+6, ph+6, pr, skirt=p_wystaje_ponizej_wylotu+6,wysokosc_nad_wylot=p_wysokosc_nad_wylot);
            }
            //heblowanie_na_gorze(pw + 100,ph/2, pr, 1.5, pr);
            translate([0,250,-pw/2-pr+1]) rotate([90,0,0]) bryla_klimatyzatora_glowna(pw,pr);
        }
        
        // przejście
        translate([0,0,ft]) hull() {
            linear_extrude(0.02) rr(pw+2*wall+2*e, ph+2*wall+2*e, pr+wall+e);
            translate([0,0,pd]) linear_extrude(0.02) square([163,143],center=true);
        }
        translate([0,0,pd+ft+15-3]) linear_extrude(3) square([170,72],center=true);
        // króciec + rowek pod opaskę
        translate([0,0,ft+pd-0.01]) linear_extrude(15) rr(163,143,4);
        //translate([0,0,ft+pd+sl*0.55]) cylinder(h=4, d=dd+2*wall+3+2*e);
    }
}

// Kanał powietrza (do odjęcia)
module inner_void() {
    union() {
        
        translate([0,0,ft+pd-40-0.01]) linear_extrude(65) rr(156,136,10);
        
        translate([0,0,-1]) linear_extrude(ft+1.01) rr(pw, ph, pr);
        translate([0,0,ft]) hull() {
            linear_extrude(0.02) rr(pw, ph, pr);
            translate([0,0,pd]) linear_extrude(0.02) rr(156,136,10);
        }
        //translate([0,0,ft+pd-0.01]) cylinder(h=sl+2, d=dd);
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
        //screw_holes();
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
