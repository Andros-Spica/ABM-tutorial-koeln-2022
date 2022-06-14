;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  The PondTrade model - Koehl ABM tutorial version
;;  Copyright (C) 2022 Andreas Angourakis (andros.spica@gmail.com)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; the gis extension allows us to read and operate standard GIS data
;; See documentation: https://ccl.northwestern.edu/netlogo/docs/gis.html
extensions [ gis ]

;;;;;;;;;;;;;;;;;
;;; BREEDS ;;;;;;
;;;;;;;;;;;;;;;;;

breed [ settlements settlement ]

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals
[
  patchesWithElevationData
  minElevation
  maxElevation

  seaLevel

  patchXpixelScale
  pixelExtentMargin
  patchSize

  width
  height

  siteMarkerScale_min siteMarkerScale_max

  ;;; GIS data holders
  sitesData_EMIII-MMIA
  sitesData_MMIB
  elevationData
  riversData

  routes
]

settlements-own
[
  ;;; from GIS data
  name
  siteType
  period

  sizeLevel
]

patches-own
[
  elevation
  isRiver

  pathCost

  ;;; path-finding related
  parent-patch ; patch's predecessor
  f ; the value of knowledge plus heuristic cost function f()
  g ; the value of knowledge cost function g()
  h ; the value of heuristic cost function h()
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  reset-timer
  clear-all

  set-parameters

  create-map

  carefully [ import-routes-from-file ] [ set-routes ]

  setup-display

  update-display

  output-print (word "Set up took " timer " seconds.")

end

to create-map

  load-gis  ;; load in the GIS data

  set-world-dimensions ;; set world dimensions according to GIS data

  setup-patches ;; use GIS data to set patch variables

  setup-settlements ;; create site agents with properties from sitesData

end

to set-parameters

  ;;; set the values of parameters, here fixed as constants

  set seaLevel 0

  ;;; for better performance, we take a multiple fraction of the dimensions of elevationData,
  ;;; so that patches will get average values or more regular sets of pixels
  ;;; for example, with patchXpixelScale = 0.15, the pixel resolution will be approx. 100m instead of 15m
  ;;; NOTE: when changing patchXpixelScale, pixelExtentMargin and patchSize may need to be adjusted accordingly)

  set patchXpixelScale    0.1 ;;; keep it less than 0.25
  set pixelExtentMargin  50
  set patchSize           3

  ;;; define scale factors for the display of settlements (percentage of width)
  set siteMarkerScale_min 0.1
  set siteMarkerScale_max 1

end

to set-world-dimensions

  set width ceiling ((pixelExtentMargin + gis:width-of elevationData) * patchXpixelScale)
  set height ceiling ((pixelExtentMargin + gis:height-of elevationData) * patchXpixelScale)

  resize-world 0 width 0 height

  set-patch-size patchSize

end

to setup-patches

  setup-elevation

  setup-rivers

  assign-path-cost

end

to setup-elevation

  gis:apply-raster elevationData elevation

  set patchesWithElevationData patches with [(elevation <= 0) or (elevation >= 0)]

  set minElevation min [elevation] of patchesWithElevationData

  set maxElevation max [elevation] of patchesWithElevationData

end

to setup-rivers

  ;print gis:feature-list-of riversData
  ask patches
  [
    set isRiver gis:intersects? riversData self
  ]

end

to assign-path-cost

  ask patches [ set pathCost 9999 ] ;;; this makes routes crossing patches with no elevation data very unlikely

  ask patchesWithElevationData
  [
    let myValidNeighborsAndI (patch-set self (neighbors with [(elevation <= 0) or (elevation >= 0)]))

    ifelse (count myValidNeighborsAndI > 1)
    [
      set pathCost standard-deviation [elevation] of myValidNeighborsAndI
    ]
    [
      set pathCost 1
    ]
  ]

end

to setup-settlements

  ;print gis:feature-list-of sitesData

  if (simulation-period = "EMIII-MMIA")
  [
    gis:create-turtles-from-points-manual sitesData_EMIII-MMIA settlements
    [["NAME" "name"] ["TYPE" "siteType"]]
    [
      set period "EMIII-MMIA"
    ]
  ]

  if (simulation-period = "MMIB")
  [
    gis:create-turtles-from-points-manual sitesData_MMIB settlements
    [["NAME" "name"] ["TYPE" "siteType"]]
    [
      set period "MMIB"
    ]
  ]

  ask settlements
  [
    set sizeLevel 1

      set shape "circle 2"
  ]

end

to set-routes

  set routes [] ; initialize/reset the routes as an empty list

  let settlementsWithoutRoutes settlements ; helper variable to keep track of which settlement already searched for routes

  ask settlements
  [
    let thisSettlement self

    ask other settlementsWithoutRoutes
    [
      let optimalRoute find-a-path ([patch-here] of thisSettlement) ([patch-here] of self) ; find the optimal route to this settlement
      set routes lput optimalRoute routes ; add the optimal route to the end of the routes list
    ]

    set settlementsWithoutRoutes other settlementsWithoutRoutes

  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Get and set routes (helper 'to-report' procedures) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report get-route [ settlement1 settlement2 ] ; accepts two settlements and returns a route

  ; get routes connecting settlement1
  let routesFromSettlement1 filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = settlement1) or
    ([one-of settlements-here] of last ?1 = settlement1)
  ] routes

  ; get the route connecting settlement2 from the previous list
  let routeFromSettlement1ToSettlement2 filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = settlement2) or
    ([one-of settlements-here] of last ?1 = settlement2)
  ] routesFromSettlement1

  report first routeFromSettlement1ToSettlement2

end

to-report get-routes-to-settlement [ aSettlement ] ; accepts a settlement and return a list of routes

  report filter
  [ ?1 ->
    ([one-of settlements-here] of first ?1 = aSettlement) or
    ([one-of settlements-here] of last ?1 = aSettlement)
  ] routes

end

to-report get-origin-and-destination [ aRoute ] ; accepts a route and returns a turtle-set with two settlements

  report (turtle-set ([ one-of settlements-here ] of first aRoute) ([one-of settlements-here ] of last aRoute))

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; A* path finding algorithm ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; modified from Meghendra Singh's Astardemo1 model in NetLogo User Community Models
; http://ccl.northwestern.edu/netlogo/models/community/Astardemo1
; modified lines/fragments are marked with ";-------------------------------*"
; In this version, patches have different movement cost.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the actual implementation of the A* path finding algorithm
; it takes the source and destination patches as inputs
; and reports the optimal path if one exists between them as output
to-report find-a-path [ source-patch destination-patch]

  ; initialize all variables to default values
  let search-done? false
  let search-path []
  let current-patch 0
  let open [] ;-------------------------------*
  let closed [] ;-------------------------------*

  ;-------------------------------*
  ask patches with [ f != 0 ]
  [
    set f 0
    set h 0
    set g 0
  ]
  ;-------------------------------*

  ; add source patch in the open list
  set open lput source-patch open

  ; loop until we reach the destination or the open list becomes empty
  while [ search-done? != true]
  [
    ifelse length open != 0
    [
      ; sort the patches in open list in increasing order of their f() values
      set open sort-by [ [?1 ?2] -> [f] of ?1 < [f] of ?2 ] open

      ; take the first patch in the open list
      ; as the current patch (which is currently being explored (n))
      ; and remove it from the open list
      set current-patch item 0 open
      set open remove-item 0 open

      ; add the current patch to the closed list
      set closed lput current-patch closed

      ; explore the Von Neumann (left, right, top and bottom) neighbors of the current patch
      ask current-patch
      [
        ; if any of the neighbors is the destination stop the search process
        ifelse any? neighbors4 with [ (pxcor = [ pxcor ] of destination-patch) and (pycor = [pycor] of destination-patch)] ;-------------------------------*
        [
          set search-done? true
        ]
        [
          ; the neighbors should not already explored patches (part of the closed list)
          ask neighbors4 with [ (not member? self closed) and (self != parent-patch) ] ;-------------------------------*
          [
            ; the neighbors to be explored should also not be the source or
            ; destination patches or already a part of the open list (unexplored patches list)
            if not member? self open and self != source-patch and self != destination-patch
            [
;              set pcolor 45 ;-------------------------------*

              ; add the eligible patch to the open list
              set open lput self open

              ; update the path finding variables of the eligible patch
              set parent-patch current-patch
              set g [g] of parent-patch + pathCost ;-------------------------------*
              set h distance destination-patch
              set f (g + h)
            ]
          ]
        ]
;        if self != source-patch ;-------------------------------*
;        [
;          set pcolor 35
;        ]
      ]
    ]
    [
      ; if a path is not found (search is incomplete) and the open list is exhausted
      ; display a user message and report an empty search path list.
      user-message( "A path from the source to the destination does not exist." )
      report []
    ]
  ]

  ; if a path is found (search completed) add the current patch
  ; (node adjacent to the destination) to the search path.
  set search-path lput current-patch search-path

  ; trace the search path from the current patch
  ; all the way to the source patch using the parent patch
  ; variable which was set during the search for every patch that was explored
  let temp first search-path
  while [ temp != source-patch ]
  [
;    ask temp ;-------------------------------*
;    [
;      set pcolor 85
;    ]
    set search-path lput [parent-patch] of temp search-path
    set temp [parent-patch] of temp
  ]

  ; add the destination patch to the front of the search path
  set search-path fput destination-patch search-path

  ; reverse the search path so that it starts from a patch adjacent to the
  ; source patch and ends at the destination patch
  set search-path reverse search-path

  print (word "Route between " source-patch " and " destination-patch " done.")

  ; report the search path
  report search-path

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; DISPLAY AND PLOT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-display

  display-rivers

  display-site-markers

  paint-elevation-of-patches

end

to update-display

  paint-routes

  ;paint-active-routes

  update-settlement-display-size

end

to display-site-markers

  if (show-site-markers and simulation-period = "EMIII-MMIA")
  [
    gis:set-drawing-color red
    gis:draw sitesData_EMIII-MMIA 1
  ]

  if (show-site-markers and simulation-period = "MMIB")
  [
    gis:set-drawing-color yellow
    gis:draw sitesData_MMIB 1
  ]

end

to display-rivers

  gis:set-drawing-color blue
  gis:draw riversData 1

end

to paint-elevation-of-patches

  ;;; paint patches according to elevation
  ;;; NOTE: we must filter out those patches outside the DEM
  ask patches with [(elevation <= 0) or (elevation >= 0)]
  [
    paint-elevation
  ]

end

to paint-elevation

  set pcolor get-elevation-color elevation

end

to-report get-elevation-color [ elevationValue ]

  let elevationGradient 0

  if (elevationValue > seaLevel)
  [
    let normSupElevation elevationValue - seaLevel
    let normSupMaxElevation maxElevation - seaLevel + 1E-6
    set elevationGradient 100 + (155 * (normSupElevation / normSupMaxElevation))
    report rgb (elevationGradient - 100) elevationGradient 0
  ]

;  if (elevationValue <= seaLevel)
;  [
;    report blue
;  ]

  report black

end

to update-settlement-display-size

  let maxSettlementSize max [sizeLevel] of settlements

  ask settlements
  [
    ; scale the size of settlements according to their dynamic free-scaled sizeLevel
    set size siteMarkerScale_min + (sizeLevel / maxSettlementSize) * siteMarkerScale_max
  ]

end

to paint-routes

  ;;; define list of shades of red in NetLogo
  let redShades (list 11 12 13 14 15 16 17 18 19)
  ;;; NOTE: this is needed because rgb colors based on elevation are a list
  ;;; while NetLogo color are numbers

  ; resets route patches to the terrain color
  foreach routes
  [ ?1 ->
    let aRoute ?1

    foreach aRoute
    [ ??1 ->
      ask ??1 [ paint-elevation ]
    ]
  ]

  ; paint route patches in shades of red depending on route frequency
  foreach routes
  [ ?1 ->
    let aRoute ?1

    foreach aRoute
    [ ??1 ->
      ask ??1
      [
        if (showRoutes)
        [
          ifelse (not member? pcolor redShades) ; if its the first route crossing the patch
          [
            set pcolor 11
          ]
          [
            set pcolor min (list (pcolor + 1) (19)) ; sets a maximum at 19 (the brightest)
          ]
        ]
      ]
    ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; DATA LOAD AND PREPARATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-gis

  ; Load all of our datasets
  set sitesData_EMIII-MMIA gis:load-dataset "data//Cretedata//EMIII_MMIAsites.shp"
  set sitesData_MMIB gis:load-dataset "data//Cretedata//MMIBsites.shp"

  set elevationData gis:load-dataset "data//Cretedata//dem15.asc"
  set riversData gis:load-dataset "data//Cretedata//rivers.shp"

  ; Set the world envelope to the union of all of our dataset's envelopes ; NOT NEEDED IF USING DEM?
  gis:set-world-envelope (gis:envelope-of elevationData)

end

to export-routes-to-file

  ;;; build a unique file name to identify current setting
  let filePath (word "data//routes//routes_" simulation-period "_patchXpixelScale=" patchXpixelScale "_pixelExtentMargin=" pixelExtentMargin"_w=" world-width "_h=" world-height "_randomSeed=" randomSeed ".txt")

  file-open filePath

  file-print (word "simulation-period: " simulation-period)
  file-print (word "patchXpixelScale: " patchXpixelScale)
  file-print (word "pixelExtentMargin: " pixelExtentMargin)
  file-print (word "width: " world-width "; height: " world-height)
  file-print (word "randomSeed: " randomSeed)

  foreach routes
  [
    aRoute ->

    file-print aRoute
  ]

  file-close

end

to import-routes-from-file

  ;;; make sure all parameter values are loaded
  set-parameters

  ;;; get unique file name corresponding to the current setting
  let filePath (word "data//routes//routes_" simulation-period "_patchXpixelScale=" patchXpixelScale "_pixelExtentMargin=" pixelExtentMargin"_w=" world-width "_h=" world-height "_randomSeed=" randomSeed ".txt")

  ifelse (not file-exists? filePath)
  [ print (word "WARNING: could not find '" filePath "'") stop ] ;;; unfortunately the stop command doesn't stop the setup procedure
  [
    file-open filePath

    let headingNumberOfLines 5

    let howHeadingLinesShouldBe (list
      (word "simulation-period: " simulation-period)
      (word "patchXpixelScale: " patchXpixelScale)
      (word "pixelExtentMargin: " pixelExtentMargin)
      (word "width: " world-width "; height: " world-height)
      (word "randomSeed: " randomSeed)
      )
    print howHeadingLinesShouldBe
    let headingLines []
    foreach (n-values headingNumberOfLines [i -> i + 1])
    [
      headingLineIndex ->
      set headingLines lput (word "" file-read-line "") headingLines
    ]
    print headingLines
    let passedCheck (
      (item 0 headingLines = item 0 howHeadingLinesShouldBe) and
      (item 1 headingLines = item 1 howHeadingLinesShouldBe) and
      (item 2 headingLines = item 2 howHeadingLinesShouldBe) and
      (item 3 headingLines = item 3 howHeadingLinesShouldBe) and
      (item 4 headingLines = item 4 howHeadingLinesShouldBe)
    )

    ifelse (not passedCheck)
    [ print (word "WARNING: " filePath " does not contain the expected metadata defining the current parameter setting") stop ] ;;; unfortunately the stop command doesn't stop the setup procedure
    [
      set routes []

      while [not file-at-end?]
      [
        let lineString file-read-line
        set lineString remove-item 0 lineString
        set lineString remove-item (length lineString - 1) lineString
        set lineString (word "(list " lineString " )")

        set routes lput (run-result lineString) routes
      ]
    ]
  ]

  file-close

end
@#$#@#$#@
GRAPHICS-WINDOW
292
16
1038
490
-1
-1
3.0
1
10
1
1
1
0
0
0
1
0
245
0
154
0
0
1
ticks
30.0

BUTTON
105
20
172
53
setup
setup
NIL
1
T
OBSERVER
NIL
0
NIL
NIL
1

BUTTON
177
181
271
214
Update display
update-display
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
26
431
266
485
11

CHOOSER
126
113
264
158
simulation-period
simulation-period
"EMIII-MMIA" "MMIB"
0

SWITCH
10
181
167
214
show-site-markers
show-site-markers
1
1
-1000

SWITCH
10
214
123
247
showRoutes
showRoutes
0
1
-1000

SWITCH
10
247
148
280
showActiveRoutes
showActiveRoutes
1
1
-1000

INPUTBOX
26
105
102
165
randomSeed
0.0
1
0
Number

BUTTON
14
63
139
96
NIL
export-routes-to-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
144
63
273
96
NIL
import-routes-from-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sailboat side
false
0
Line -16777216 false 0 240 120 210
Polygon -7500403 true true 0 239 270 254 270 269 240 284 225 299 60 299 15 254
Polygon -1 true false 15 240 30 195 75 120 105 90 105 225
Polygon -1 true false 135 75 165 180 150 240 255 240 285 225 255 150 210 105
Line -16777216 false 105 90 120 60
Line -16777216 false 120 45 120 240
Line -16777216 false 150 240 120 240
Line -16777216 false 135 75 120 60
Polygon -7500403 true true 120 60 75 45 120 30
Polygon -16777216 false false 105 90 75 120 30 195 15 240 105 225
Polygon -16777216 false false 135 75 165 180 150 240 255 240 285 225 255 150 210 105
Polygon -16777216 false false 0 239 60 299 225 299 240 284 270 269 270 254

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
