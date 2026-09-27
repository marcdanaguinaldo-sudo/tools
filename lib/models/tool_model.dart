class ToolStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String gripTip;
  final String targetAngle;

  const ToolStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.gripTip,
    required this.targetAngle,
  });
}

class ToolModel {
  final String id;
  final String name;
  final String localName; // Ilokano / Tagalog / English
  final String category;
  final String difficulty;
  final String description;
  final String safetyTip;

  /// Optional model metadata stored for compatibility with trained assets.
  /// This is not shown in the UI and does not drive inference.
  final int? classId;

  /// Estimated time to finish the guided lesson, in minutes.
  final int minutes;
  final List<String> warnings;
  final List<ToolStep> steps;

  const ToolModel({
    required this.id,
    required this.name,
    required this.localName,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.safetyTip,
    this.classId,
    required this.minutes,
    required this.warnings,
    required this.steps,
  });
}

/// Category identifiers shared by the catalog, the filters, and the manual picker.
class ToolCategories {
  static const cutting = 'Cutting & Chopping';
  static const measuring = 'Measuring';
  static const mixing = 'Mixing & Preparing';
  static const straining = 'Straining & Cleaning';
  static const cooking = 'Cooking & Serving Utensils';
  static const misc = 'Misc / Accessories';

  static const ordered = [
    cutting,
    measuring,
    mixing,
    straining,
    cooking,
    misc,
  ];
}

/// Rich built-in tool repository (100% offline ready).
///
/// Ids are stable and are the join key for saved progress, favourites, and the
/// recognition model. Never rename an id without a migration.
const List<ToolModel> kBuiltInTools = [
  // ---------------------------------------------------------------- cutting
  ToolModel(
    id: 'knife',
    name: "Chef's Knife (8\")",
    localName: "Kutsilio ti Kusina",
    category: ToolCategories.cutting,
    difficulty: "Intermediate",
    description:
        "Multipurpose kitchen knife for precision slicing, dicing, and mincing.",
    safetyTip:
        "Always curl your guide hand into the Bear Claw grip. Never place your index finger flat along the knife spine.",
    classId: 48,
    minutes: 6,
    warnings: [
      "Always maintain the Claw Grip with your guide fingers tucked safely.",
      "Anchor your cutting board with a damp towel underneath to eliminate sliding.",
      "Never leave blades submerged in soapy sink water where edges become invisible.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Bolster Pinch Grip",
        instruction:
            "Pinch the blade bolster firmly between thumb and curled index finger.",
        gripTip:
            "The knife is an organic extension of your forearm. Never place your index finger along the top spine.",
        targetAngle: "Neutral 0° wrist deviation",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Bear Claw Defense Stance",
        instruction:
            "Curl guide hand into a tight claw. Flat guide knuckles fence the flat knife blade.",
        gripTip: "Tuck thumb behind curled guide knuckles at all times.",
        targetAngle: "90° perpendicular knuckle fence",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Rolling Rocking Cut",
        instruction:
            "Keep knife tip anchored lightly to the board. Roll belly forward and down in a rhythmic wave.",
        gripTip:
            "Let blade weight cut through produce without hammering down with brute arm force.",
        targetAngle: "15° to 20° edge contact arc",
      ),
      ToolStep(
        stepNumber: 4,
        title: "4. Clean & Stow",
        instruction:
            "Hand wash with warm sudsy sponge pointing away from blade. Dry and store in wood block or sheath.",
        gripTip: "Never clean with sponge facing toward the razor edge.",
        targetAngle: "Flat surface wipe",
      ),
    ],
  ),
  ToolModel(
    id: 'paring_knife',
    name: "Paring Knife (4\")",
    localName: "Maliit na Kutsilio",
    category: ToolCategories.cutting,
    difficulty: "Beginner",
    description:
        "Short-bladed control knife for peeling, trimming, and shaping produce in your hand.",
    safetyTip:
        "Only use a paring knife on a board once you have cut larger knives with confidence. In-hand work is for advanced users.",
    minutes: 4,
    warnings: [
      "Never attempt in-hand peeling until in-hand knife control is genuinely comfortable.",
      "Keep the blade tip pointed down and away from your supporting palm.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Board Setup",
        instruction:
            "Place a damp towel under a small board so the whole board cannot slide while you work.",
        gripTip:
            "A paring knife is fast and short. Stability beats speed at every level.",
        targetAngle: "0° board lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Pencil Grip, Close to the Tip",
        instruction:
            "Hold the handle near the bolster like a pencil, thumb and index pinching the tang.",
        gripTip:
            "Choking up shortens the lever arm so small corrections stay under control.",
        targetAngle: "45° pencil grip",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Shaving Cuts",
        instruction:
            "Take thin downward slices, shaving the surface layer rather than halving the item.",
        gripTip:
            "Rotate the produce, not the knife, so your wrist stays neutral and the tip never tracks toward you.",
        targetAngle: "20° to 30° shave angle",
      ),
    ],
  ),
  ToolModel(
    id: 'cleaver',
    name: "Chinese Cleaver",
    localName: "Kutsilio ng Buto",
    category: ToolCategories.cutting,
    difficulty: "Advanced",
    description:
        "Massive rectangular blade built for hacking through bone, cleaving greens, and crushing garlic.",
    safetyTip:
        "A cleaver's edge is far longer than a chef's knife. Treat every downward stroke as a two-handed commitment.",
    minutes: 6,
    warnings: [
      "CRITICAL: A cleaver is never a one-handed tool. Both hands commit before the blade moves.",
      "Clear a wide landing zone so the blade never lands on a stray handle or cloth.",
      "Do not use a cleaver on frozen food; it chips and can glance off unpredictably.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Two-Hand Commitment Grip",
        instruction:
            "Wrap the full handle in your dominant hand. Place your other hand flat on the top spine, away from the edge.",
        gripTip:
            "The spine hand only guides. If you are squeezing with it, you are pressing instead of chopping.",
        targetAngle: "Full-hand wrap grip",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Hinge Chop",
        instruction:
            "Keep the blade tip planted and pivot the handle up and down from the wrist, like a door on a hinge.",
        gripTip:
            "Do not lift the whole blade. Lifting removes the weight that makes the cut clean.",
        targetAngle: "15° to 25° hinge arc",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Flat-Side Crush",
        instruction:
            "Lay the blade flat and press the non-cutting side down on garlic, ginger, or pumpkin skin to release the skin.",
        gripTip:
            "The flat side carries no edge, so it is safe to press with. Never do this with the sharpened side.",
        targetAngle: "90° face contact",
      ),
    ],
  ),
  ToolModel(
    id: 'kitchen_shears',
    name: "Kitchen Shears",
    localName: "Gunting ng Kusina",
    category: ToolCategories.cutting,
    difficulty: "Beginner",
    description:
        "Heavy spring-loaded shears for joint work, herb snipping, and opening packages one-handed.",
    safetyTip:
        "Do not use shears on bones or frozen goods. Prying the handles wide can eject the blade assembly.",
    minutes: 3,
    warnings: [
      "Cut only what scissors can cut. Bones and frozen items will blunt or split the blades.",
      "Wipe blades before stowing; a scissor left wet will rust along the pivot.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Open Hand Placement",
        instruction:
            "Slide the middle finger through the lower handle ring and the ring finger through the upper ring.",
        gripTip:
            "Fingers in the rings give you leverage for tough stems without squeezing your palm.",
        targetAngle: "Neutral wrist, fingers seated",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Snip, Do Not Shear Through",
        instruction:
            "Close the blades in short decisive snips, letting each cut complete before reopening.",
        gripTip:
            "Half-open blades cut cleaner and keep your sightline to the cut line.",
        targetAngle: "15° blade opening",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Wipe and Stow",
        instruction:
            "Open the shears wide and wipe both blades and the pivot dry with a clean cloth.",
        gripTip: "Store loosely closed so the spring is not held compressed all day.",
        targetAngle: "Full open dry",
      ),
    ],
  ),
  ToolModel(
    id: 'cutting_board',
    name: "Cutting Board",
    localName: "Lalamunan",
    category: ToolCategories.cutting,
    difficulty: "Beginner",
    description:
        "Stable work surface that protects your knife edge, your counter, and your wrists.",
    safetyTip:
        "A board that moves is a board that causes cuts. Anti-slip feet or a damp towel are not optional.",
    minutes: 4,
    warnings: [
      "Replace a board once knife marks reach the seams; deep grooves hide bacteria.",
      "Never use a glass or stone surface for cutting. It destroys knife edges instantly.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Lock the Board Down",
        instruction:
            "Set the board on a damp towel and press the corners until it does not shift under a hard shove.",
        gripTip:
            "Test with a firm push before every session. If it moves, the towel is too dry.",
        targetAngle: "0° counter lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Working Sides and Zones",
        instruction:
            "Use one half for raw protein and the other half for produce. Mark the split mentally every time.",
        gripTip:
            "Cross-contamination is invisible. A consistent half-and-half habit prevents it.",
        targetAngle: "Two-zone layout",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Wash, Dry, Stand Up",
        instruction:
            "Scrub both faces, dry upright in a rack so air circulates, and never store it flat while damp.",
        gripTip:
            "Trapped moisture is what breeds mould in the grooves you cannot see.",
        targetAngle: "Upright storage",
      ),
    ],
  ),
  ToolModel(
    id: 'peeler',
    name: "Y-Shaped Vegetable Peeler",
    localName: "Pambalat ng Gulay",
    category: ToolCategories.cutting,
    difficulty: "Beginner",
    description:
        "Ergonomic Y-frame peeler with twin carbon steel blades for precision skinning.",
    safetyTip:
        "Always peel in strokes directed away from your holding hand and body.",
    minutes: 3,
    warnings: [
      "Always peel in smooth strokes directed strictly away from holding hand.",
      "Anchor the bottom of root vegetables against a cutting board for stability.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Board Anchor Tripod",
        instruction:
            "Rest bottom end of produce against cutting board at an angle for solid tripod stability.",
        gripTip:
            "Holding hand fingers stay firmly at top 20% of vegetable, behind the stroke zone.",
        targetAngle: "45° board stability angle",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Long Glide Ribbon Stroke",
        instruction:
            "Pull peeler downward in continuous light strokes. Pivoting twin blades hug the contour.",
        gripTip:
            "Let blade sharpness remove outer skin without digging into nutritious flesh.",
        targetAngle: "20° pivot contact plane",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Blemish Eye Remover",
        instruction:
            "Use the loop tip on the peeler shoulder to gouge potato eyes and root blemishes cleanly.",
        gripTip: "Twist with thumb fulcrum rather than prying with arm force.",
        targetAngle: "90° gouge rotation",
      ),
    ],
  ),
  ToolModel(
    id: 'grater',
    name: "Box Grater",
    localName: "Kaso",
    category: ToolCategories.cutting,
    difficulty: "Beginner",
    description:
        "Four-sided stainless grater for cheese, zest, and fine shreds from a stable flat-foot stance.",
    safetyTip:
        "Never grate while holding food in your fingers over the blade face. Use the flat side until you are confident on the box sides.",
    minutes: 4,
    warnings: [
      "Hold food against the flat face, not your fingertips, whenever you are near an edge.",
      "Keep fingers at least 15 cm from the cutting holes. Fingers cannot reliably feel a sharp hole through food.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Flat-Foot Secure Stance",
        instruction:
            "Stand the grater on its wide base on a damp towel, or brace the base against your hip.",
        gripTip:
            "A grater that tips mid-stroke pulls the food straight into the holes.",
        targetAngle: "0° base lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Push Stroke, Lifted Fingers",
        instruction:
            "Push food away from you with the heel of your hand, fingers curled flat and lifted clear.",
        gripTip:
            "The heel of the hand does the work. Fingertips only stabilise from behind.",
        targetAngle: "45° push stroke",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Switch Sides by Lifting",
        instruction:
            "Lift the grater to rotate to a different face rather than trying to turn it under your hand.",
        gripTip: "Lifting breaks the contact that is keeping your hand too close to the holes.",
        targetAngle: "Vertical lift to rotate",
      ),
    ],
  ),
  ToolModel(
    id: 'zester',
    name: "Citrus Zester",
    localName: "Katas ng Sitsit",
    category: ToolCategories.cutting,
    difficulty: "Intermediate",
    description:
        "Fine-pore zester that lifts the coloured zest layer and leaves the bitter white pith behind.",
    safetyTip:
        "Zest with the fruit on a board, never braced in your palm. A zester removes skin in one pass and cuts deep on the second.",
    minutes: 4,
    warnings: [
      "Always rest the fruit on a board. Zesters are designed to skin, not to dig.",
      "Stop when you see white pith; pith is bitter and there is no way to remove it once grated.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Firm Fruit Base",
        instruction:
            "Press the fruit cut-side down into a bowl or against a rubber mat so it cannot roll.",
        gripTip:
            "Rolling fruit is how zesters find knuckles. Fix the fruit before you fix your grip.",
        targetAngle: "0° fruit lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Light Layer, Lift and Turn",
        instruction:
            "Draw the zester across the skin in one smooth pass, then rotate the fruit a few degrees and repeat.",
        gripTip:
            "Shallow passes take coloured oil. Heavy passes take pith you cannot undo.",
        targetAngle: "15° grazing angle",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Recover the Zest",
        instruction:
            "Scrape the outer skin off the zester's shoulder into a bowl to keep every drop of oil.",
        gripTip: "The shoulder collects more oil than the holes do, and it is usually discarded by mistake.",
        targetAngle: "Perpendicular scrape",
      ),
    ],
  ),
  ToolModel(
    id: 'mandoline',
    name: "Precision Mandoline Slicer",
    localName: "Pang-hiwa ng Repolyo",
    category: ToolCategories.cutting,
    difficulty: "Advanced",
    description:
        "Adjustable Japanese-style mandoline slicer for paper-thin juliennes and chips.",
    safetyTip:
        "NEVER use a mandoline without the safety hand guard or a level 5 cut-resistant glove.",
    minutes: 5,
    warnings: [
      "CRITICAL: Always use the safety pusher guard. Never guide produce with bare fingers.",
      "Lock blade to 'SAFE' position immediately after use before cleaning.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Food Pusher Locking",
        instruction:
            "Spear vegetable firmly onto the safety food guard's stainless steel prongs.",
        gripTip:
            "Your hand must rest entirely on the pusher dome, never on the slicing bed.",
        targetAngle: "Vertical prong lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Thickness Dial Calibration",
        instruction:
            "Turn rear thickness dial to desired slice gauge (1mm for chips, 3mm for slaw).",
        gripTip:
            "Calibrate dial with blade pointed down, safely away from fingers.",
        targetAngle: "Fine micrometer calibration",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Rhythmic Downward Slide",
        instruction:
            "Glide pusher smoothly down the angled ramp through the V-blade with uniform pressure.",
        gripTip:
            "Smooth rhythm produces perfectly identical, uniform slices that cook evenly.",
        targetAngle: "30° ramp gliding stroke",
      ),
    ],
  ),

  // -------------------------------------------------------------- measuring
  ToolModel(
    id: 'dry_measuring_cups',
    name: "Dry Measuring Cups",
    localName: "Mga Tasa ng Dry",
    category: ToolCategories.measuring,
    difficulty: "Beginner",
    description:
        "Nested cups with a level-off rim for scooping flour, sugar, and other dry goods.",
    safetyTip:
        "Do not pack dry ingredients down. A packed cup is a different measurement and will skew every recipe that follows.",
    minutes: 3,
    warnings: [
      "Scoop and level. Never scoop and shake or tap the cup to settle the flour.",
      "Keep cups nested on a hook rather than stacked on a shelf where a nested cup can be shaken loose.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Insert, Do Not Stack",
        instruction:
            "Pull the cup you need fully clear of the nested set before filling it.",
        gripTip:
            "A spoon left in a nested cup lifts and spills the whole set.",
        targetAngle: "Vertical lift",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Fill Over the Rim",
        instruction:
            "Fill past the rim, then slide the back edge of a spoon or a knife flat across the top to level it.",
        gripTip:
            "Level from the back of the cup toward you so the blade cannot drag flour back in.",
        targetAngle: "0° level-off plane",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Tap, Then Return",
        instruction:
            "Tap the side of the cup once to release clinging powder, then return the cup to the set before the next measure.",
        gripTip:
            "Tapping is for emptying the cup, not for settling the measure.",
        targetAngle: "Single wrist tap",
      ),
    ],
  ),
  ToolModel(
    id: 'liquid_measuring_cup',
    name: "Liquid Measuring Cup",
    localName: "Baso ng Tubig",
    category: ToolCategories.measuring,
    difficulty: "Beginner",
    description:
        "Clear graduated jug with a pour spout for accurate liquid volumes at eye level.",
    safetyTip:
        "Never fill hot liquid to the brim. Thermal expansion pushes liquid out of the spout even when the level looks correct.",
    minutes: 3,
    warnings: [
      "Read at eye level. Looking down over the meniscus gives a reading that is too high.",
      "Leave headroom for hot liquids; a full cup of boiling water will overflow the spout.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Set the Jug Flat",
        instruction:
            "Place the jug on a level counter and fill until the liquid sits just below the line you need.",
        gripTip:
            "Do not hold the jug at eye height to fill. You cannot read a line and control volume at the same time.",
        targetAngle: "0° level surface",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Eye-Level Reading",
        instruction:
            "Crouch until your eyes are level with the line and read the bottom of the meniscus, not its top.",
        gripTip:
            "The curved meniscus is the liquid's edge. Its top ring holds a film of water above the true level.",
        targetAngle: "0° line of sight",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Pour From the Spout",
        instruction:
            "Tip the jug so liquid leaves from the spout corner, keeping the handle above the rim.",
        gripTip:
            "If liquid runs down the outside of the jug, you are pouring too slowly and losing volume.",
        targetAngle: "Spout-leading pour",
      ),
    ],
  ),
  ToolModel(
    id: 'measuring_spoons',
    name: "Measuring Spoons",
    localName: "Kutsara ng Sukat",
    category: ToolCategories.measuring,
    difficulty: "Beginner",
    description:
        "Nested stainless spoon set with a leveler, for the small volumes that decide seasoning.",
    safetyTip:
        "Never use a measuring spoon to stir while it is still on your hand. Set it down or use a separate stirring spoon.",
    minutes: 3,
    warnings: [
      "Do not nest spoons while they are wet; trapped moisture promotes rust at the ring.",
      "Use the leveler, not a finger scrape, to top off a small measure.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Choose and Separate",
        instruction:
            "Detach the spoon you need and lay it on a flat surface, rounded side down.",
        gripTip:
            "A spoon held in your hand cannot be filled accurately and cannot be levelled.",
        targetAngle: "0° spoon rest",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Fill and Level",
        instruction:
            "Fill the spoon, then pass the handle of a second spoon across the top to shave off the excess.",
        gripTip:
            "Level with a straight edge, not with a fingertip. Finger tips add what you remove.",
        targetAngle: "0° level-off plane",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Add, Then Rest",
        instruction:
            "Empty the spoon into the pan, rest it on the spoon rest, and re-measure rather than reusing a loaded spoon.",
        gripTip:
            "Returning a partly used spoon to the nest contaminates every other measure.",
        targetAngle: "Rest between measures",
      ),
    ],
  ),
  ToolModel(
    id: 'kitchen_scale',
    name: "Digital Weighing Scale",
    localName: "Timbangan ng Kusina",
    category: ToolCategories.measuring,
    difficulty: "Beginner",
    description:
        "Platform scale that removes the guesswork from every dry measure and portion control.",
    safetyTip:
        "Never place the scale directly over the hob or inside a sink. It is an electrical device.",
    minutes: 3,
    warnings: [
      "Wipe the platform before each use. A hidden crumb throws the reading off by grams.",
      "Keep the scale on a flat, dry surface away from steam and splashing water.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Zero It Every Time",
        instruction:
            "Turn the scale on with nothing on the platform and confirm it reads exactly zero.",
        gripTip:
            "Tare before every batch. A cup left on the platform is a silent offset.",
        targetAngle: "0 g reference",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Weigh Into a Vessel",
        instruction:
            "Place your bowl or container first, tare again, then add ingredient until you reach the target weight.",
        gripTip:
            "Tare with the vessel in place so you weigh the ingredient, not the container.",
        targetAngle: "Tare with vessel",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Read the Settled Value",
        instruction:
            "Wait for the number to stop changing before you adjust, because the reading settles as flour settles.",
        gripTip:
            "Grabbing the reading mid-settle is the most common source of baking inconsistency.",
        targetAngle: "Settled readout",
      ),
    ],
  ),

  // ----------------------------------------------------------------- mixing
  ToolModel(
    id: 'bowl',
    name: "Mixing Bowls",
    localName: "Mangkok",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Deep hemispherical bowls for whipping batters, folding dough, and dressings.",
    safetyTip:
        "Anchor the bowl with a damp towel ring so it cannot spin freely while whisking or folding.",
    classId: 50,
    minutes: 4,
    warnings: [
      "Stabilize the bowl base to prevent sudden spin-offs that spill hot or heavy ingredients.",
      "Never strike metal spoons aggressively against tempered glass bowl rims.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Countertop Anchor Setup",
        instruction:
            "Place a damp towel ring beneath the bowl to help prevent it from slipping.",
        gripTip:
            "Keep the bowl steady with your other hand and use a comfortable grip.",
        targetAngle: "0° flat countertop lock",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. 30° Rim Clamp Stance",
        instruction:
            "Clamp support palm over rolled rim. Tilt bowl 30° toward your chest for visual control.",
        gripTip:
            "Keep all fingertips strictly on the exterior rim perimeter to avoid utensil collisions.",
        targetAngle: "30° ergonomic tilt",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Bottom-to-Rim Fold",
        instruction:
            "Sweep spoon from bottom center up the wall in a continuous folding curve, aerating evenly.",
        gripTip:
            "Generate sweeping momentum from wrist cadence rather than stiff shoulder movement.",
        targetAngle: "45° spoon entry sweep",
      ),
    ],
  ),
  ToolModel(
    id: 'whisk',
    name: "Wire Whisk",
    localName: "Batiador",
    category: ToolCategories.mixing,
    difficulty: "Intermediate",
    description:
        "Multi-wire stainless whisk for rapid aeration, meringues, and emulsions.",
    safetyTip:
        "Whip using a side-to-side shearing wave rather than wide circular stirring to aerate 3x faster.",
    minutes: 4,
    warnings: [
      "Whip from the wrist and forearm, not the shoulder, to avoid rotator cuff strain.",
      "Anchor the bowl with a towel ring to prevent bowl wobble at high speed.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Pencil vs. Palm Grip",
        instruction:
            "Hold the whisk handle close to the wire collar like a large pencil for maximum speed.",
        gripTip:
            "Choke up on the collar to shorten the lever arm and double your agitation frequency.",
        targetAngle: "45° ergonomic pencil grip",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. High-Velocity Shearing Wave",
        instruction:
            "Agitate the whisk in rapid side-to-side ellipses across the bowl bottom to shear proteins.",
        gripTip:
            "Side-to-side shearing introduces 3x more air bubbles than lazy circular stirring.",
        targetAngle: "Horizontal 180° wave oscillation",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Peak Emulsion Check",
        instruction:
            "Lift whisk vertically out of batter to inspect peak stiffness (soft, medium, or stiff gloss).",
        gripTip:
            "Gently tap whisk collar against inside rim to release residual batter.",
        targetAngle: "Vertical 90° lift",
      ),
    ],
  ),
  ToolModel(
    id: 'wooden_spoon',
    name: "Wooden Spoon",
    localName: "Kutsara ng Kahoy",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Wooden spoon for stirring, folding, and scraping that will not scratch a coated pan.",
    safetyTip:
        "Wood conducts heat poorly, but the handle is still long enough to burn. Keep it out of a hot pan's vapour path.",
    minutes: 3,
    warnings: [
      "Do not leave a wooden spoon soaking overnight; standing water splits the grain and grows mould.",
      "Never leave a wooden spoon standing in a hot sauce; the handle conducts heat upward.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Loose Three-Finger Hold",
        instruction:
            "Hold the handle between thumb and fingers near the top, resting the butt of the spoon in your palm.",
        gripTip:
            "A loose hold lets you feel resistance from the mixture. A death grip only tires your hand.",
        targetAngle: "Neutral wrist",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Sweep the Base",
        instruction:
            "Drag the spoon along the bottom of the pan in a figure of eight so nothing catches and scorches.",
        gripTip:
            "Anything that sits still in a hot pan will stick. Keep the whole floor moving.",
        targetAngle: "Continuous figure-of-eight",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Rest on the Pan Rim",
        instruction:
            "Rest the spoon across a pan rim or a spoon rest, not standing on the counter.",
        gripTip:
            "A cross-contaminated raw-to-cooked spoon resting on the counter is how bacteria travel.",
        targetAngle: "Rim rest, not counter",
      ),
    ],
  ),
  ToolModel(
    id: 'spatula',
    name: "Spatula",
    localName: "Espatula",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Flat-bladed turner for flipping, folding, and scraping pans clean without a second utensil.",
    safetyTip:
        "Never tap a hot pan with the blade to test heat. Use a drop of water or a flicker of your hand above the surface.",
    minutes: 3,
    warnings: [
      "Rubber blades melt if they rest in a pan on the heat. Choose metal for high-heat work.",
      "Keep the blade handle joint clear of the flame if you are working over a gas hob.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Slide to the Far Edge",
        instruction:
            "Slide the blade fully under the food until the tip reaches the far side before you commit to the flip.",
        gripTip:
            "A partial slide lifts the middle and folds the food onto itself.",
        targetAngle: "Flat blade, 0° entry",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Wrist-Led Rotation",
        instruction:
            "Rotate your wrist so the far edge lifts and the blade rolls the food over in one continuous arc.",
        gripTip:
            "Rotate from the wrist, not the shoulder. Your elbow should stay roughly where it is.",
        targetAngle: "90° wrist arc",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Scrape the Pan Floor",
        instruction:
            "Tilt the pan toward the blade and pull the spatula through the fond in one pass to deglaze.",
        gripTip:
            "Let the blade meet the pan almost flat; a blade held upright leaves a crescent behind.",
        targetAngle: "Blade near-parallel to floor",
      ),
    ],
  ),
  ToolModel(
    id: 'rubber_scraper',
    name: "Rubber Scraper",
    localName: "Kutsara ng Latex",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Heat-proof flexible scraper that retrieves batter from bowl walls and sweeps a hot pan clean.",
    safetyTip:
        "Only a scraper rated for the heat can sit in the pan. Ordinary rubber will melt and leach into food.",
    minutes: 3,
    warnings: [
      "Check the heat rating printed on the scraper before it goes near a hot pan.",
      "Replace a scraper once it is torn or has blackened; the nicks cut food fibres and trap residue.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Flex the Blade Against the Wall",
        instruction:
            "Press the blade against the inside wall of the bowl and pull it down, forcing batter into the centre.",
        gripTip:
            "Flex the blade against the wall, do not use the blade edge. The wall is the cutting tool.",
        targetAngle: "Blade flexed to 0° wall contact",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Pan Sweep in Stages",
        instruction:
            "Tilt the pan to pool the liquid, then draw the scraper through it in one pass to lift the fond.",
        gripTip:
            "Work from the far side toward you so you always push liquid away from your hand.",
        targetAngle: "Sweep far to near",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Split the Batch",
        instruction:
            "Use the scraper to divide dough or batter into even portions on a tray, then lift with it.",
        gripTip:
            "A scraper divides cleanly because it has no edge to catch the dough.",
        targetAngle: "Flat transfer",
      ),
    ],
  ),
  ToolModel(
    id: 'rolling_pin',
    name: "Rolling Pin",
    localName: "Pindang",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Evenly weighted cylinder for rolling dough to a consistent, even thickness.",
    safetyTip:
        "Never roll toward yourself with your fingers extended past the pastry. Fingers walk into the dough, and then into the roller.",
    minutes: 5,
    warnings: [
      "Keep fingers inside the dough's edge and behind the roller's path at all times.",
      "Flour the surface before the first pass. Dough that sticks to the pin tears instead of rolling.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Flour the Surface Twice",
        instruction:
            "Dust the worktop and the dough, then press the dough flat with your palms before you roll.",
        gripTip:
            "Start from a flattened disc, not a ball. Rolling a ball first creates thick and thin patches.",
        targetAngle: "Flattened disc base",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Roll Away, Lift, Return",
        instruction:
            "Roll outward from the centre, then lift the pin and return to the starting point each time.",
        gripTip:
            "Rolling back and forth over the same strip builds thickness in one band and leaves the rest thin.",
        targetAngle: "Outward stroke, 0° return",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Rotate the Dough, Not the Pin",
        instruction:
            "Turn the dough a quarter turn every few passes so the pressure spreads evenly in all directions.",
        gripTip:
            "Rotate the dough and the pin's stroke direction changes without moving your whole body.",
        targetAngle: "90° rotation per quarter",
      ),
    ],
  ),
  ToolModel(
    id: 'pastry_brush',
    name: "Pastry Brush",
    localName: "Pambote",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Soft-bristled brush for egg washes, glazes, and oiling pastry without tearing the dough.",
    safetyTip:
        "Keep the bristle band well below the pan rim when working over heat so steam does not swell and loosen the bristles.",
    minutes: 3,
    warnings: [
      "Do not boil a silicone or nylon brush. High heat destroys the bonding that holds the bristles.",
      "Wash a pastry brush in warm soapy water and dry it with the bristles hanging down.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Load and Offload",
        instruction:
            "Dip one third of the bristle length into your wash, then tap the brush on the rim of the bowl.",
        gripTip:
            "A fully loaded brush drips and overcoats. Tap off the excess every single stroke.",
        targetAngle: "One third bristle dip",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Sweep, Do Not Scrub",
        instruction:
            "Sweep the brush in long even strokes from the centre outwards toward the edges.",
        gripTip:
            "Pressing drags bristles. Gliding lays an even film and keeps the pastry surface intact.",
        targetAngle: "45° bristle rake",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Dry Hang",
        instruction:
            "Rinse, squeeze out excess water, and hang the brush bristle-down on a hook away from the hob.",
        gripTip:
            "A brush lying flat dries with the bristle side crushed, which permanently bends the band.",
        targetAngle: "Bristle-down hang",
      ),
    ],
  ),
  ToolModel(
    id: 'mortar_pestle',
    name: "Mortar & Pestle",
    localName: "Sangan at Tumbung",
    category: ToolCategories.mixing,
    difficulty: "Intermediate",
    description:
        "Heavy stone pair for grinding spices, pounding garlic, and making pastes without a machine.",
    safetyTip:
        "Never grind with a metal spoon in a stone mortar. A steel edge chips the stone and leaves metal in your food.",
    minutes: 5,
    warnings: [
      "Grind in short pulses. Long continuous grinding walks the pestle against the wall and chips it.",
      "Cracked or chipped stone cannot be cleaned properly and should be discarded.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Brace the Mortar",
        instruction:
            "Set the mortar on a folded damp cloth and press down with your free hand so it cannot creep.",
        gripTip:
            "Stone on stone is slick. Brace the base before the pestle goes anywhere near it.",
        targetAngle: "0° base brace",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Angle the Pestle Down",
        instruction:
            "Press the pestle into the ingredients leaning into the bowl wall, then rotate it back through the centre.",
        gripTip:
            "Leaning the pestle uses the bowl wall as a second grinding surface, so less arm force is needed.",
        targetAngle: "20° to 30° pestle lean",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Scrape the Wall",
        instruction:
            "Every few passes, scrape the paste back off the wall into the centre with the pestle end.",
        gripTip:
            "Paste left on the wall dries out, goes bitter, and stops being ground.",
        targetAngle: "180° scrape sweep",
      ),
    ],
  ),
  ToolModel(
    id: 'potato_masher',
    name: "Potato Masher",
    localName: "Pambasa",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Perforated masher that flattens cooked potatoes to a consistent texture without the glue of a blender.",
    safetyTip:
        "Mash only fully cooked, hot potatoes. A raw or undercooked potato can contain resistant starch that will not break down.",
    minutes: 3,
    warnings: [
      "Do not mash a whole potato that has cooled; it will break into hard dry lumps.",
      "Press the masher away from your body and keep your knuckles clear of the pot rim.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Press, Do Not Swing",
        instruction:
            "Set the masher into the potatoes and press straight down, then lift and reposition.",
        gripTip:
            "Swinging a masher sideways splashes hot mash out of the pot.",
        targetAngle: "90° vertical press",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Rotate as You Press",
        instruction:
            "Twist the masher a quarter turn on every press so the perforations never mash the same spot twice.",
        gripTip:
            "The perforations are the working edge. Rotating between presses is what makes it work.",
        targetAngle: "90° twist per press",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Add Liquid Last",
        instruction:
            "Add butter, milk, or oil only after the mash is smooth, then fold gently to keep it light.",
        gripTip:
            "Liquid added early makes the mash gluey before the starch has cooked out.",
        targetAngle: "Gentle folding",
      ),
    ],
  ),
  ToolModel(
    id: 'garlic_press',
    name: "Garlic Press",
    localName: "Pindot ng Bawang",
    category: ToolCategories.mixing,
    difficulty: "Beginner",
    description:
        "Lever press that forces whole cloves through a perforated chamber in a single squeeze.",
    safetyTip:
        "Never reach into a press to clear a stuck clove with a finger. Use the cleaning tool or the cleaning slot designed for it.",
    minutes: 3,
    warnings: [
      "Keep hands out of the chamber at all times; the mechanism can close unexpectedly under spring load.",
      "Press the chamber, not the handle, when loading so the chamber is not already under pressure.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Load Under the Chamber",
        instruction:
            "Break the bulb into single cloves, peel them, and drop one or two into the cup you just opened.",
        gripTip:
            "Two cloves at most. Overloading is what jams the mechanism and forces you to pick it apart.",
        targetAngle: "Unpressured chamber",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Squeeze to the Stop",
        instruction:
            "Bring the handles together with both hands until the chamber bottoms out, then release fully.",
        gripTip:
            "Ease off pressure between cloves so the plunger can reset. Forcing a double press jams the press.",
        targetAngle: "Two-handed squeeze",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Use the Rack or the Slot",
        instruction:
            "Scrape the pressed garlic out with the silicone brush stored on the press, or push the grid through the cleaning slot.",
        gripTip:
            "The cleaning slot exists so you never need a finger, a knife, or running water on the chamber.",
        targetAngle: "Perpendicular scrape",
      ),
    ],
  ),

  // -------------------------------------------------------------- straining
  ToolModel(
    id: 'colander',
    name: "Colander",
    localName: "Salak",
    category: ToolCategories.straining,
    difficulty: "Beginner",
    description:
        "Large perforated bowl for draining pasta, washed greens, and deep-fried batches.",
    safetyTip:
        "Set a colander over the sink and check that it is stable before you pour. A colander full of boiling water that tips causes a scald.",
    minutes: 3,
    warnings: [
      "Never lift a full colander of boiling liquid by the rim alone; the rim is wet and hot.",
      "Let steam dissipate before reaching over the holes; a burst of vapour burns at the wrist.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Seat and Check the Balance",
        instruction:
            "Rest the colander in the sink and press one side down hard to confirm it cannot tip.",
        gripTip:
            "A colander resting on two rim points and a lifted third point will tip at the worst moment.",
        targetAngle: "0° rim seating",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Tip Away From You",
        instruction:
            "Tip the pot so the pour lip points into the colander and away from your body and forearm.",
        gripTip:
            "Pouring toward yourself is what turns a normal drain into a scald on the inner arm.",
        targetAngle: "45° controlled pour",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Shake, Then Steam Clear",
        instruction:
            "Shake the colander once to drain, then hold it back and out of the rising steam for a moment.",
        gripTip:
            "Colander holes hold hot water. Give it a moment over the sink before your hand goes near the rim.",
        targetAngle: "Hands clear of steam column",
      ),
    ],
  ),
  ToolModel(
    id: 'strainer',
    name: "Fine-Mesh Strainer",
    localName: "Salain",
    category: ToolCategories.straining,
    difficulty: "Beginner",
    description:
        "Tight-weave sieve for straining custards, stocks, and sauces free of lumps and seeds.",
    safetyTip:
        "Support the strainer under its rim with a second hand whenever it is full. Fine mesh sags and the pan is always hot.",
    minutes: 4,
    warnings: [
      "Do not rest a loaded strainer on the rim of a pan. The rim is thin and the weight will distort it.",
      "Keep your fingers spread and flat underneath the mesh, never hooked over it.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Two-Hand Rim Support",
        instruction:
            "Hold the strainer by its rim with one hand and cup the underside with the other.",
        gripTip:
            "The supporting hand goes flat and wide, never through the mesh and never hooked around it.",
        targetAngle: "Two-point rim grip",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Pour Into the Back Third",
        instruction:
            "Pour into the far side of the mesh and let the liquid drain across toward you.",
        gripTip:
            "Pouring into the middle builds pressure that pushes solids and hot liquid back over the near rim.",
        targetAngle: "Far-third pour entry",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Press the Solids, Not the Mesh",
        instruction:
            "Press the retained solids with the back of a spoon against the mesh, away from the near edge.",
        gripTip:
            "Never tip the strainer towards yourself to speed draining. The retained solids will slide over the rim.",
        targetAngle: "Downward press, far from rim",
      ),
    ],
  ),
  ToolModel(
    id: 'sieve',
    name: "Sieve / Sifter",
    localName: "Sift",
    category: ToolCategories.straining,
    difficulty: "Beginner",
    description:
        "Fine drum sieve that aerates and de-lumps flour in two shakes before it ever meets liquid.",
    safetyTip:
        "Sift over a bowl, never over a bare counter. A cloud of fine flour is easy to inhale and easy to slip on.",
    minutes: 3,
    warnings: [
      "Never sift flour directly onto a wet surface; the dust will adhere and can be inhaled when it dries.",
      "Tap the sieve rim rather than shaking it near your face, so the flour falls rather than billows.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Coarse Sift First",
        instruction:
            "Sift the flour once with a coarse mesh to break up compacted lumps and any weevil fragments.",
        gripTip:
            "A coarse pass first is what removes lumps. A fine sieve cannot break a lump, only pass flour through.",
        targetAngle: "0° sieve tilt over bowl",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Two Sharp Shakes",
        instruction:
            "Hold the sieve a few centimetres above the bowl and shake it firmly twice, not continuously.",
        gripTip:
            "Two decisive shakes are more effective than ten nervous ones and keep the flour dust down.",
        targetAngle: "2° oscillation, twice",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Tap the Rim Down",
        instruction:
            "Tap the sieve rim on the bowl edge so the flour that is sitting on the mesh falls through.",
        gripTip:
            "Residual flour on the inside of the mesh is a measurable loss in every batch.",
        targetAngle: "Perpendicular rim tap",
      ),
    ],
  ),
  ToolModel(
    id: 'funnel',
    name: "Funnel",
    localName: "Bumbung",
    category: ToolCategories.straining,
    difficulty: "Beginner",
    description:
        "Tapered spout for decanting oil, stock, and batters into narrow jars and bottles.",
    safetyTip:
        "Always insert the funnel stem fully and support the receiving jar. Funnels tip when the jar is nearly full.",
    minutes: 3,
    warnings: [
      "Keep the stem seated in the container at all times. A floating stem is what tips a full jar.",
      "Wipe the outside of the stem before you lift the funnel; oil drips off it after it is out.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Seat the Stem",
        instruction:
            "Place the funnel stem fully inside the receiving jar and rest the cone rim on the jar mouth.",
        gripTip:
            "A stem that is only resting on the mouth will tip the moment the jar is three quarters full.",
        targetAngle: "Vertical stem, 0° lean",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Rest the Cone on the Mouth",
        instruction:
            "Let the cone sit on the jar rim so the funnel is carried by the jar, not by your hand alone.",
        gripTip:
            "Once it is seated you can release the cone completely and pour with one hand.",
        targetAngle: "0° cone seating",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Wipe Before You Lift",
        instruction:
            "Wipe the outside of the stem with a damp cloth, then lift the funnel straight up.",
        gripTip:
            "Residual oil runs down the stem as you lift and lands outside the jar, on your hands.",
        targetAngle: "Vertical lift",
      ),
    ],
  ),

  // ---------------------------------------------------------------- cooking
  ToolModel(
    id: 'ladle',
    name: "Soup Ladle",
    localName: "Mapanaw ng Sop",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Deep-bowled serving spoon for soups, stews, and curries that carries liquid without spilling.",
    safetyTip:
        "Serve towards the bowl and away from your body. A full ladle held over the table pours the moment it tilts too far.",
    minutes: 3,
    warnings: [
      "Never fill a ladle to the brim. A full ladle has no reserve and will drip the whole way.",
      "Watch the handle for heat transfer when serving straight from a simmering pot.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Skim From the Far Side",
        instruction:
            "Lower the ladle into the pot at the far side and fill it away from you.",
        gripTip:
            "Filling away from your body means any spill happens in front of you, not on you.",
        targetAngle: "0° bowl immersion",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Two-Thirds Full",
        instruction:
            "Stop at about two thirds full and let the liquid settle for a moment before you lift.",
        gripTip:
            "The third of headroom is what stops the ladle dripping down the outside of the bowl.",
        targetAngle: "Two thirds capacity",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Pour Into the Far Side of the Bowl",
        instruction:
            "Tip the ladle so the bowl of the recipient fills from its far side, away from the diner's hands.",
        gripTip:
            "Pouring to the far side keeps the surface calm and stops liquid running out over the near rim.",
        targetAngle: "45° tip, far-side pour",
      ),
    ],
  ),
  ToolModel(
    id: 'tongs',
    name: "Serving Tongs",
    localName: "Pang-sipit",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Stainless tongs with scalloped tips for turning food and serving without a second tool.",
    safetyTip:
        "Always perform the tension test before reaching into a hot pan or a grease splatter zone.",
    minutes: 3,
    warnings: [
      "Perform the click-clack test to verify spring tension before approaching heat.",
      "Keep hands behind heat silicone guards to prevent steam and grease burns.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Unlock & Click-Clack Test",
        instruction:
            "Push rear lock ring in and click heads twice to confirm fluid spring tension return.",
        gripTip:
            "Ensure instant, crisp spring recoil without hinge stiffness or binding.",
        targetAngle: "30° spring extension",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Gentle Scallop Clamp",
        instruction:
            "Cradle food delicately between scalloped heads without piercing delicate crusts or searing.",
        gripTip:
            "Maintain knuckles 25 cm back from skillet hot grease splatter radius.",
        targetAngle: "Parallel clamping contact",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Flip Away & Rear Lock",
        instruction:
            "Turn proteins gently away from you to direct grease splatter backward. Pull rear ring to lock closed.",
        gripTip:
            "Lock tongs closed before storing to preserve spring longevity.",
        targetAngle: "180° smooth flip",
      ),
    ],
  ),
  ToolModel(
    id: 'turner',
    name: "Turner / Flipper",
    localName: "Patalabag",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Wide slotted turner for flipping burgers, eggs, fish fillets, and pancakes in a pan.",
    safetyTip:
        "Do not use a metal turner on a non-stick surface. It will gouge the coating and the pan will then need replacing.",
    minutes: 3,
    warnings: [
      "Match the tool to the surface: metal for cast iron and steel, silicone or wood for non-stick and enamel.",
      "Do not scratch a non-stick pan. Once the coating is scored, food will stick permanently.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Get Under the Whole Food",
        instruction:
            "Slide the blade all the way in so the leading edge emerges past the far side of the food.",
        gripTip:
            "Anything you cannot get fully under will fold or break when you lift it.",
        targetAngle: "0° flat entry",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Tilt and Roll",
        instruction:
            "Tip the pan slightly and roll the turner under the food so it rests partly on the pan wall.",
        gripTip:
            "The tilted pan and the roll together let you lift heavier food without a big yank.",
        targetAngle: "20° pan tilt",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Rest Until the Flake Releases",
        instruction:
            "Wait until the food releases from the pan freely, then turn it in one confident motion.",
        gripTip:
            "If it is stuck, it is not ready. Forcing it tears the crust and sticks the surface again.",
        targetAngle: "Free release, then 90° turn",
      ),
    ],
  ),
  ToolModel(
    id: 'pasta_server',
    name: "Pasta Fork / Server",
    localName: "Tinik ng Pasta",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Wide toothed spoon that lifts and twirls a portion of pasta without tearing or clumping.",
    safetyTip:
        "Do not lift pasta out of boiling water with a short handle. Use the long-handled server and keep the pot rim in front of you.",
    minutes: 3,
    warnings: [
      "Keep the pot rim between the steam and your forearm when you reach over boiling water.",
      "Do not overfill a portion. A heaped server that spills is a bigger scalding risk than a small one.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Coiled Lift",
        instruction:
            "Scoop under the pasta and rotate the server so the strands coil loosely against the bowl.",
        gripTip:
            "A loose coil holds. A tight wound spring of pasta will slide straight back into the pot.",
        targetAngle: "90° wrist rotation",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Two-Thirds and Tap the Bottom",
        instruction:
            "Fill to two thirds, then tap the server against the pot rim once to let the water drain off.",
        gripTip:
            "One firm tap on the rim drains the excess. Shaking in mid-air spreads hot splatter.",
        targetAngle: "Two thirds capacity",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Present Tilted Away",
        instruction:
            "Carry the portion with the bowl slightly forward so the coil settles in the centre of the plate.",
        gripTip:
            "A forward tilt keeps the strands from sliding off the serving end during the walk to the table.",
        targetAngle: "15° forward tilt",
      ),
    ],
  ),
  ToolModel(
    id: 'baster',
    name: "Baster",
    localName: "Baster",
    category: ToolCategories.cooking,
    difficulty: "Intermediate",
    description:
        "Bulb-and-syringe tool that moves melted fat under the skin of meat and keeps it basting evenly.",
    safetyTip:
        "Fill the bulb only about a third full. A full bulb squirts hot fat the moment you squeeze it.",
    minutes: 4,
    warnings: [
      "Squeeze the bulb gently. A hard press turns basting into a high-pressure spray of hot fat.",
      "Keep the fat away from the flame. Added liquid dripping onto a gas burner causes a flare-up.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. One-Third Fill",
        instruction:
            "Fill the rubber bulb about a third full of hot fat and push the nozzle firmly into the spigot.",
        gripTip:
            "A one third fill leaves the headroom that makes the flow controllable.",
        targetAngle: "One third capacity",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Test the Flow Before the Roast",
        instruction:
            "Squeeze gently over a spoon to confirm a slow, steady drizzle comes out of the nozzle.",
        gripTip:
            "If it spits, the nozzle is blocked with congealed fat. Clear it before it goes near hot skin.",
        targetAngle: "Slow drizzle",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Puncture and Deposit Deep",
        instruction:
            "Pierce the skin at intervals, push the nozzle just under the surface, and release fat while withdrawing.",
        gripTip:
            "Deposit fat under the skin, not on top of it. Surface fat just runs off and burns.",
        targetAngle: "Shallow skin puncture",
      ),
    ],
  ),
  ToolModel(
    id: 'dredger',
    name: "Dredger",
    localName: "Dredger",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Fine-mesh flour shaker for a controlled, even coating on fried food, cutlets, and bakes.",
    safetyTip:
        "Shake the dredger over the food only. Flour dust in the air is a fire risk and a breathing hazard.",
    minutes: 3,
    warnings: [
      "Never shake a dredger near an open flame or a hot oil surface. Flour dust is combustible.",
      "Wipe the mesh before use; old flour trapped in the drum will clump and drop into hot oil.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Fill Below the Mesh Line",
        instruction:
            "Fill the drum to just below the mesh so flour cannot pack against the lid.",
        gripTip:
            "Overfilled drums jam and drop clumps instead of a fine even dust.",
        targetAngle: "Fill below mesh line",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Hold High, Shake Lightly",
        instruction:
            "Hold the dredger 20 cm above the food and shake in short light taps to lay down a thin coat.",
        gripTip:
            "A fine dusting is a film. A thick coat fries into a batter and absorbs far more fat.",
        targetAngle: "20 cm drop height",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Double-Tap to Clear the Mesh",
        instruction:
            "Tap the bottom of the drum twice on the counter edge to shake loose any flour stuck in the mesh.",
        gripTip:
            "Clear the mesh away from the pan. Tapping over hot oil drops clumps straight into it.",
        targetAngle: "Tap away from heat",
      ),
    ],
  ),
  ToolModel(
    id: 'skimmer',
    name: "Skimmer",
    localName: "Pala",
    category: ToolCategories.cooking,
    difficulty: "Beginner",
    description:
        "Wide flat-mesh spoon for lifting crumbs, foam, and floating aromatics out of hot oil or stock.",
    safetyTip:
        "Lower the skimmer away from you and keep the mesh angled so hot liquid drains back into the pot, never onto your arm.",
    minutes: 3,
    warnings: [
      "Lower the skimmer blade away from your body. A raised blade drips straight down your forearm.",
      "Do not rest a dripping skimmer on the hob rim; the handle conducts heat straight to your hand.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Lower Blade First, Away From You",
        instruction:
            "Slide the mesh into the pot blade first, on the far side, so hot liquid drains away from your body.",
        gripTip:
            "Handle first means liquid runs down the handle into your wrist. Blade first is the safe order.",
        targetAngle: "0° blade, 30° to the far side",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Scoop Under the Surface",
        instruction:
            "Sweep just below the surface to catch floating crumbs without scooping oil.",
        gripTip:
            "A shallow sweep lifts debris and drains immediately. A deep scoop brings a ladleful of oil with it.",
        targetAngle: "20 cm below surface",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Drain Held Clear of the Rim",
        instruction:
            "Hold the skimmer clear of the pot rim for a moment and let the oil run back before approaching.",
        gripTip:
            "Drain over the pot, not over the hob. A dripping skimmer sets oil alight on a flame.",
        targetAngle: "Drain over pot centre",
      ),
    ],
  ),

  // ------------------------------------------------------------------- misc
  ToolModel(
    id: 'can_opener',
    name: "Can Opener",
    localName: "Pambuka ng Lata",
    category: ToolCategories.misc,
    difficulty: "Beginner",
    description:
        "Side-cut or crank opener that lifts a clean lid without leaving a sharp, ragged seam in the can.",
    safetyTip:
        "Always cut on the top face. The rim left by a base cut folds inward into a razor edge that cuts fingers for months afterwards.",
    minutes: 3,
    warnings: [
      "Open only on the top face. A rim cut from the base folds inward into a concealed sharp edge.",
      "Do not reach into a can with a still-attached lid. Peel the lid back against the can wall first.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Clamp on the Top Rim",
        instruction:
            "Seat the cutting wheel on the top face of the can, just inside the rim, with the wheel touching the lid.",
        gripTip:
            "The cutter belongs on the lid, not on the seam. If it is on the seam you are cutting the wrong face.",
        targetAngle: "0° wheel to lid face",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Turn the Key, Not the Can",
        instruction:
            "Rotate the crank smoothly while keeping the opener clamped still against the rim.",
        gripTip:
            "Rotating the can instead of the key makes the wheel skid and tear the seam.",
        targetAngle: "0° can rotation",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Bend the Lid Inward",
        instruction:
            "Grip the cut edge with pliers or a cloth, bend the lid down and inward against the can wall, then lift it away.",
        gripTip:
            "Bending the lid inward against the wall is what makes the sharp edge face the can instead of you.",
        targetAngle: "180° inward fold",
      ),
    ],
  ),
  ToolModel(
    id: 'bottle_opener',
    name: "Bottle Opener",
    localName: "Pambuka ng Botol",
    category: ToolCategories.misc,
    difficulty: "Beginner",
    description:
        "Compact lever or waiter-style opener for beer, cider, and soda bottles without a second tool.",
    safetyTip:
        "Keep the bottle neck pointed away from your face when the cap releases. Caps fly, and broken glass goes everywhere.",
    minutes: 3,
    warnings: [
      "Point the cap away from your face and your guests before you lever it off.",
      "Inspect the opener's grip teeth. A worn opener slips off the cap and crushes the glass rim.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Seat the Opener on the Cap",
        instruction:
            "Hook the opener's lip under the cap rim and rest the toothed plate flat on top of the cap.",
        gripTip:
            "A lip that is not fully under the rim will skid off and leave the cap crushed but attached.",
        targetAngle: "0° plate on cap top",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Firm Lever, Straight Up",
        instruction:
            "Brace the bottle against your thigh and lever the opener up in one short, firm movement.",
        gripTip:
            "A slow long lever is what bends the opener. Use the short movement your leverage gives you.",
        targetAngle: "45° lever, then vertical",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Cover the Pour",
        instruction:
            "Keep a thumb over the opening and pour slowly down the side of the glass.",
        gripTip:
            "A thumb over the mouth stops the crown cap landing in the glass and the beer going flat.",
        targetAngle: "Thumb over the mouth",
      ),
    ],
  ),
  ToolModel(
    id: 'corkscrew',
    name: "Corkscrew",
    localName: "Tornilyo",
    category: ToolCategories.misc,
    difficulty: "Intermediate",
    description:
        "Wing or pull-type corkscrew that extracts a cork intact instead of pushing it into the wine.",
    safetyTip:
        "Keep the bottle neck away from your face while pulling a cork. A broken cork fragment can be propelled by the pressure inside.",
    minutes: 4,
    warnings: [
      "Never leave a bottle open and forgotten after removing a cork; the wine oxidises within hours.",
      "If the cork breaks, pour through a strainer rather than fishing fragments out with a utensil.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Centre the Helix on the Cork",
        instruction:
            "Place the spiral dead centre on the cork face and keep the bottle upright.",
        gripTip:
            "An off-centre helix cuts the cork sideways and shatters it in the neck.",
        targetAngle: "0° helix alignment",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Screw In, Do Not Ram",
        instruction:
            "Turn the handle steadily until the helix disappears into the cork for about two thirds of its length.",
        gripTip:
            "Screwing slowly is slower once and faster three times over. Ramming the helix breaks the cork.",
        targetAngle: "Single turn per rotation",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Lever and Cover the Pour",
        instruction:
            "Lift the wings to pull the cork, then tip the bottle away from you and pour with a thumb over the neck.",
        gripTip:
            "Tip the bottle away so any spillage misses you, and keep a thumb over the mouth as it pours.",
        targetAngle: "Lever up, bottle away",
      ),
    ],
  ),
  ToolModel(
    id: 'sharpening_steel',
    name: "Sharpening Steel",
    localName: "Haspe",
    category: ToolCategories.misc,
    difficulty: "Advanced",
    description:
        "Honing rod and emery board that realign a rolled edge and restore the bite of a working knife.",
    safetyTip:
        "A honing steel removes metal. It is not a sharpener, and a badly used steel can thin a knife faster than a stone does.",
    minutes: 5,
    warnings: [
      "Angle the edge to the rod at roughly 20° to your body. Vertical strokes will roll the edge, not fix it.",
      "Work away from the cutting edge direction. A steel is a blade, and it cuts.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Check the Rod Before Use",
        instruction:
            "Run a fingernail along the rod. Any groove deep enough to catch means the steel is finished.",
        gripTip:
            "A grooved steel cannot align an edge; it just polishes a damaged one.",
        targetAngle: "Rod inspection",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. 20° Angle, Strokes Away From You",
        instruction:
            "Lay one heel of the blade flat on the rod, lift the spine until the gap is about a coin's thickness, and hone.",
        gripTip:
            "A 20° angle to the rod is the equivalent of a 40° edge, which is the right working angle for a kitchen knife.",
        targetAngle: "20° to the rod",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Even Pressure, Then Stow",
        instruction:
            "Use identical pressure on both sides, three or four passes each, and wipe the blade clean afterwards.",
        gripTip:
            "Uneven pressure rounds one side more than the other and leaves a knife that only cuts one way.",
        targetAngle: "Matched pressure both sides",
      ),
    ],
  ),
  ToolModel(
    id: 'oven_mitts',
    name: "Oven Mitts / Pot Holders",
    localName: "Mga Sizingkwit",
    category: ToolCategories.misc,
    difficulty: "Beginner",
    description:
        "Heat-rated hand protection for pan handles, oven racks, and hot plates that a dry towel cannot survive.",
    safetyTip:
        "Check the heat rating on the label. A cotton dish towel near a flame is not a pot holder, however handy it looks.",
    minutes: 3,
    warnings: [
      "Verify the temperature rating. Many decorative mitts are rated for comfort only, not for contact heat.",
      "Keep mitts away from the gas flame; the outer fabric can scorch while the padding still feels cool.",
    ],
    steps: [
      ToolStep(
        stepNumber: 1,
        title: "1. Dry Mitts Only",
        instruction:
            "A wet mitt conducts heat straight through the padding and scalds you instantly.",
        gripTip:
            "Wet fabric defeats the trapped air that makes insulation work. Dry is the whole point.",
        targetAngle: "Fully dry fabric",
      ),
      ToolStep(
        stepNumber: 2,
        title: "2. Grip the Handle's Cool End",
        instruction:
            "Slide your hand well in so the mitt covers your wrist, then grip the handle at the end furthest from the pan.",
        gripTip:
            "Gripping the middle of a long handle puts your mitt right where the heat conducts.",
        targetAngle: "Grip at the cool end",
      ),
      ToolStep(
        stepNumber: 3,
        title: "3. Clear the Air, Then Stow Wide",
        instruction:
            "Set hot items down on a trivet, not on a cloth, and hang the mitts open so the heat can escape.",
        gripTip:
            "A folded mitt insulates itself and stays hot enough to burn the next person who reaches for it.",
        targetAngle: "Open hang, full air",
      ),
    ],
  ),
];
