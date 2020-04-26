include <polyholes.scad>
include <build_plate.scad>


/* [Walls] */

// What style of body design?
wall_design = 2;  // [1:Straight-wall box, 2:Tapered-wall box, 3:Raked nose+tail]

// How thick should the walls of the enclosure be? (millimeters)
wall_thickness = 5;    // [1:30]

/* [Payload] */

// How wide should the payload compartment area be? (millimeters)
payload_width = 140;

// How long should the payload compartment area be? (millimeters)
payload_length = 190;

// How deep should the payload compartment area be? (millimeters)
payload_depth = 20;


/* [Screw holes] */

// How many holes should there be on each side of the enclosure? 0 will disable holes.
hole_count = 3;     // [0:5]

// What diameter screw hole should be made? (millimeters)
hole_diameter = 3;

// What diameter of screw head should be allowed? (millimeters)
counterbore_diameter = 8;

// How wide should the radius around the screw holes should the flange lip be? 0 will disable (millimeters)
screw_lip_width = 10; // [0:50]

// How thick should the flange lip be? (millimeters)
screw_lip_thickness = 4;


/* [Oversized splitting] */
//when your printer bed is too small to fit the entire model.
split_half = 0;  //[0:No splitting,1:Half (1 of 2),2:Half (2 of 2)]


/* [Build plate] */
//for display only, doesn't contribute to final object
build_plate_selector = 0; //[0:Replicator 2,1: Replicator,2:Thingomatic,3:Manual]
 
//when Build Plate Selector is set to "manual" this controls the build plate x dimension 
build_plate_manual_x = 100; //[100:400] 
 
//when Build Plate Selector is set to "manual" this controls the build plate y dimension 
build_plate_manual_y = 100; //[100:400]

build_plate(build_plate_selector,build_plate_manual_x,build_plate_manual_y);
 


if (split_half == 0) {
    // print the whole part.
    print_part();
} else if (split_half == 1) {
    // split in half, print part 1 of 2
    rotate([0, 0, 90])
    translate([-payload_length/4, 0, 0])
    intersection() {
        translate([0, -500, -500]) cube(1000, 1000, 1000);
        print_part();
    }
} else if (split_half == 2) {
    // split in half, print part 2 of 2
    rotate([0, 0, 90])
    translate([payload_length/4, 0, 0])
    intersection() {
        translate([-1000, -500, -500]) cube(1000, 1000, 1000);
        print_part();
    }
}

module print_part() {
    difference() {
        // this is the actual solid parts of the model.
        union() {
            if (wall_design == 1) {
                print_case_part1();
            } else if (wall_design == 2) {
                print_case_part2();
            } else if (wall_design == 3) {
                print_case_part3();
            }
            print_screw_lips();
        }
        
        // everything below is subtracted from the above parts.
        print_payload_part();
        print_screwholes();
    }
}

module print_screw_lips() {
    if (hole_count > 0 && screw_lip_width > 0) {

        hull() {
            for(side = [ -1 : 2 : 1] ) {            // -1 and +1
                pos_y = side * (payload_width + 1.5 * counterbore_diameter) / 2;
                
                for(hole = [ 1 : hole_count] ) {
                    pos_x = (-0.5 + hole / (hole_count + 1)) * (payload_length + 2 * wall_thickness);
                    
                    translate([pos_x, pos_y, 0]) {
                        // extra thickness around the counterbore area
                        //translate([0, 0, -(payload_depth * 2)])
                        //polyhole(h = payload_depth * 2, d = 2 * counterbore_diameter);
                        
                        // lip around the base of one mounting screw
                        translate([0, 0, -screw_lip_thickness])
                        cylinder(h = screw_lip_thickness, d = 2 * screw_lip_width);
                    }
                }
            }        
        }
    }
}


module print_screwholes() {
    
    // we use polyhole instead of cylinder to ensure better fit.
    // https://hydraraptor.blogspot.com/2011/02/polyholes.html
    // https://github.com/SolidCode/MCAD/blob/master/polyholes.scad
    if (hole_count > 0) {
    
        for(side = [ -1 : 2 : 1] ) {            // -1 and +1
            pos_y = side * (payload_width + 1.5 * counterbore_diameter) / 2;
            
            for(hole = [ 1 : hole_count] ) {
                pos_x = (-0.5 + hole / (hole_count + 1)) * (payload_length + 2 * wall_thickness);
                
                translate([pos_x, pos_y, 0]) {
                    // hole for screw shank
                    // we make this triple thickness to ensure it fully cuts through the bottom of the object and the bottom of the counterbore.
                    translate([0, 0, -screw_lip_thickness * 2])
                    polyhole(h = screw_lip_thickness * 3, d = hole_diameter);
                
                    // counterbore for head of screw
                    translate([0, 0, -(payload_depth * 2 + screw_lip_thickness)])
                    polyhole(h = payload_depth * 2, d = counterbore_diameter);
                }
            }
        }
    }
}


// Case with tapered (drafted) walls and raked nose+tail.
module print_case_part3() {
    nose_angle = 15;            // 0-45, smaller numbers look better.
    nose_thickness = 2*wall_thickness;
    
    translate([0, 0, -(payload_depth+wall_thickness) ])
    linear_extrude(height = payload_depth + wall_thickness,
        center = false, convexity = 0, twist = 0, scale=1.125) {
        
        polygon(points=[
            [payload_length / 2, payload_width / 2 + wall_thickness],
            [payload_length / 2 + nose_thickness, 
                payload_width / 2 + wall_thickness - nose_thickness / tan(nose_angle)],
            [payload_length / 2 + nose_thickness,
                -(payload_width / 2 + wall_thickness - nose_thickness / tan(nose_angle))],
            [payload_length / 2, -(payload_width / 2 + wall_thickness)],
            [-payload_length / 2, -(payload_width / 2 + wall_thickness)],
            [-(payload_length / 2 + nose_thickness),
                -(payload_width / 2 + wall_thickness - nose_thickness / tan(nose_angle))],
            [-(payload_length / 2 + nose_thickness), 
                payload_width / 2 + nose_thickness - nose_thickness / tan(nose_angle)],
            [-payload_length / 2, payload_width / 2 + wall_thickness]
            ]);
    }
}


// Case with tapered (drafted) walls.
module print_case_part2() {
    translate([0, 0, -(payload_depth+wall_thickness) ])
    linear_extrude(height = payload_depth + wall_thickness,
        center = false, convexity = 0, twist = 0, scale=1.125) {
        
        square([payload_length + 2 * wall_thickness, 
            payload_width + 2 * wall_thickness], center=true);
    }
}

// Case with straight walls
module print_case_part1() {
    translate([-payload_length / 2 - wall_thickness,
            -payload_width / 2 - wall_thickness,
            -(payload_depth + wall_thickness)]) {
        cube([payload_length + 2 * wall_thickness,
                payload_width + 2 * wall_thickness,
                payload_depth + wall_thickness]);
    }
}

// Volume representing the hollow cavity where the payload will go.
module print_payload_part() {
    translate([-payload_length / 2, -payload_width / 2, -payload_depth]) {
        // we make this double-depth so that it fully cuts through the bottom of the object.
        cube([payload_length, payload_width, payload_depth * 2]);
    }
    
}