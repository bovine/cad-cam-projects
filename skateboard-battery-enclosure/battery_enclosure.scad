include <polyholes.scad>
include <build_plate.scad>


/* [Walls] */

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


/* [Build plate] */
//for display only, doesn't contribute to final object
build_plate_selector = 0; //[0:Replicator 2,1: Replicator,2:Thingomatic,3:Manual]
 
//when Build Plate Selector is set to "manual" this controls the build plate x dimension 
build_plate_manual_x = 100; //[100:400] 
 
//when Build Plate Selector is set to "manual" this controls the build plate y dimension 
build_plate_manual_y = 100; //[100:400]

build_plate(build_plate_selector,build_plate_manual_x,build_plate_manual_y);
 



print_part();

module print_part() {
    difference() {
        // this is the actual solid parts of the model.
        union() {
            print_case_part2();
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
                pos_x = side * (payload_width + 1.5 * counterbore_diameter) / 2;
                
                for(hole = [ 1 : hole_count] ) {
                    pos_y = (-0.5 + hole / (hole_count + 1)) * (payload_length + 2 * wall_thickness);
                    
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
            pos_x = side * (payload_width + 1.5 * counterbore_diameter) / 2;
            
            for(hole = [ 1 : hole_count] ) {
                pos_y = (-0.5 + hole / (hole_count + 1)) * (payload_length + 2 * wall_thickness);
                
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


// Case with tapered (drafted) walls
module print_case_part2() {
    translate([0, 0, -(payload_depth+wall_thickness) ])
    linear_extrude(height = payload_depth + wall_thickness,
        center = false, convexity = 0, twist = 0, scale=1.125) {
        
        square([payload_width + 2 * wall_thickness, 
                    payload_length + 2 * wall_thickness], center=true);
    }
    
}

// Case with straight walls
module print_case_part1() {
    // TODO: consider also trying chamfered cube?
    // https://github.com/SebiTimeWaster/Chamfers-for-OpenSCAD/blob/master/Chamfer.scad
    
    translate([-payload_width / 2 - wall_thickness, 
            -payload_length / 2 - wall_thickness, -(payload_depth+wall_thickness)]) {
        cube([payload_width + 2 * wall_thickness, 
                payload_length + 2 * wall_thickness, 
                payload_depth + wall_thickness]);
    }
    
}

// Volume representing the hollow cavity where the payload will go.
module print_payload_part() {
    translate([-payload_width / 2, -payload_length / 2, -payload_depth]) {
        // we make this double-depth so that it fully cuts through the bottom of the object.
        cube([payload_width, payload_length, payload_depth * 2]);
    }
    
}