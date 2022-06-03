# Archaeological ABM at Cologne: from concept to application
Materials for the session organized by the [CoDArchLab](http://archaeoinformatik.uni-koeln.de/) in the Institute of Archaeology at University of Cologne (20/6/2022).

This exercise introduces the basic concepts and workflow of Agent-based modelling (ABM), as it is used in archaeology. More specifically, it covers the prototyping of a conceptual model into a working simulation model, the 'refactoring' of code (cleaning, restructuring, optimizing), the re-use of published model parts and algorithms, the exploration of alternative designs, and the use of geographic, climatic and archaeological data to apply the model to a specific case study. The tutorial offers implementation examples of path cost analysis, hydrological and land productivity modelling, network dynamics and cultural evolution.

This tutorial uses [NetLogo](https://ccl.northwestern.edu/netlogo/), a flexible well-established modelling platform that is known for its relatively low-level entry requirements in terms of programming experience. It has been particularly used in social sciences and ecology, both for research and pedagogic purposes.

## Table of contents

- [Archaeological ABM at Cologne: from concept to application](#archaeological-abm-at-cologne-from-concept-to-application)
  - [Table of contents](#table-of-contents)
  - [Preparation](#preparation)
  - [Introduction](#introduction)
    - [Mathematical models](#mathematical-models)
    - [ABM main concepts](#abm-main-concepts)
    - [ABM in archaeology](#abm-in-archaeology)
    - [SES framework](#ses-framework)
    - [Modelling 'steps'](#modelling-steps)
    - [Modelling '(mis)steps'](#modelling-missteps)
    - [References](#references)
  - [Tutorial](#tutorial)
    - [Block A](#block-a)
      - [Definition of domain/phenomenon/question](#definition-of-domainphenomenonquestion)
      - [Conceptual model](#conceptual-model)
      - [NOTE #1: models as reference](#note-1-models-as-reference)
      - [Getting to know NetLogo](#getting-to-know-netlogo)
      - [NOTE #2: other platforms/languages](#note-2-other-platformslanguages)
      - [Prototyping](#prototyping)
    - [Block B](#block-b)
      - [NetLogo basics](#netlogo-basics)
      - [Test-drive: drawing a terrain with code](#test-drive-drawing-a-terrain-with-code)
      - [Verification-refactoring cycle](#verification-refactoring-cycle)
      - [Modularity and re-use](#modularity-and-re-use)
      - [NOTE #3: where to find modules](#note-3-where-to-find-modules)
      - [Exploring alternative and additional designs](#exploring-alternative-and-additional-designs)
    - [Block C](#block-c)
      - [Integrating spatial data as input](#integrating-spatial-data-as-input)
      - [Integrating time-series data as input](#integrating-time-series-data-as-input)
      - [NOTE #4: degrees of model calibration](#note-4-degrees-of-model-calibration)
      - [Formating and exporting output data](#formating-and-exporting-output-data)
      - [Strategies for model 'validation'](#strategies-for-model-validation)

## Preparation

To prepare for the tutorial, you only need to:

- Download and install the latest version of NetLogo. The system-specific installation files are found here: https://ccl.northwestern.edu/netlogo/download.shtml
- Download or 'clone' the contents of this repository into a local folder. Select ![Code](images/Code-button.png) in the top right of the repository page in GitHub, and choose one of the options given.

---
---
## Introduction

---
### Mathematical models

: mechanism- vs. pattern-driven models

---
### ABM main concepts

In contrast with other mechanistic and dynamic mathematical modelling approaches, ABM seeks to represent a phenomenon by explicitly modeling its constituents parts. Therefore, ABM involves the expectation that the phenomenon at the macro-level is an *emergency* of the dynamics at the micro-level. Moreover, ABM implies that the parts, the agents, constitute 'populations', *i.e.* they share common properties and behavioral rules. The 'agency' behind the term 'agent' also implies that these parts have certain autonomy with respect to each other and the environment, which justifies simulating their behavior at an individual level.

In practice, 'autonomy' often translates as the agents' ability to take action, to move, to decide, or even think and remember. Nevertheless, agent-based models also include entities that are *technically* agents (on the terms of [multi-agent systems](https://en.wikipedia.org/wiki/Multi-agent_system)), but lack those abilities or are not considered real discrete entities. The most common case is to represent sectors of space as agents fixed to unique positions in a grid to facilitate the implementation of distributed spatial processes (*e.g.*, the growth of vegetation dependent on local factors). In NetLogo, this type of agent is pre-defined as `patches` and is extensively used in models in ecology and geography.

Compared to other modeling and simulation approaches, ABM is more intuitive but also more complex. For example, the [Lotka-Volterra predator-prey model](https://en.wikipedia.org/wiki/Lotka%E2%80%93Volterra_equations) in ecology is a pair of differential equations that are relatively simple and conceptually straightforward. They essentially express the following dynamics:

>assumption: prey population grows based on unspecified resources (*intrinsic growth rate*)   
>more prey -> more food for predators, so more predators will survive and reproduce  
>more predators -> more prey will be killed, so fewer prey will survive and reproduce  
>less prey -> less food for predators, so fewer predators will survive and reproduce  
>fewer predator -> fewer prey will be killed, so more prey will survive and reproduce  
>more prey -> more food ... (the cycle begins again)

<p style="text-align: center;">
<a title="AspidistraK, CC BY-SA 4.0 &lt;https://creativecommons.org/licenses/by-sa/4.0&gt;, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Lotka_Volterra_dynamics.svg"><img width="400" alt="Lotka Volterra dynamics" src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/16/Lotka_Volterra_dynamics.svg/512px-Lotka_Volterra_dynamics.svg.png"></a>
<br>
<i style="color: grey;">Example of Lotka Volterra dynamics</i>
</p>

The same model can also be implemented with ABM (see the comparison in [NetLogo's Model Library Wolf-Sheep Predation (Docked Hybrid)](http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation(DockedHybrid))). The ABM implementation requires many additional specifications on how predator and prey agents should behave individually. Even though it is not strictly necessary, ABM variations of the Lotka-Volterra model will often aim to include more complexity. In the case of the Wolf-Sheep model mentioned, there is an explicit account of the base resource (*i.e.* the prey of the prey), named `grass`, which is implemented as a property of spatial units. These additional specifications normally help the model to be more intuitive and realistic, but also complicate the model design and implementation significantly, even though generating the same aggregate dynamics of the equation-based version (*i.e.*, oscillation harmony between prey and predator populations).

<p style="text-align: center;">
<a title="SethTisue, GPL &lt;http://www.gnu.org/licenses/gpl.html&gt;, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Netlogo-ui.png"><img width="512" alt="Netlogo-ui" style="width: 450px; height: 350px; object-fit: cover; object-position: 0% 0%;" src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Netlogo-ui.png/512px-Netlogo-ui.png"></a>
<br>
<i style="color: grey;">NetLogo user interface running the Wolf-Sheep Predation model</i>
</p>

Another important and distinctive aspect of agent-based models is that they are unavoidably *stochastic*. By definition, the order in which agents of a type perform their processes should not be predefined and, overall, should not be the same followed every iteration of the model. This is (normally) not the case in models based on differential/difference equations, where the equations calculating variables are solved following a particular fixed order. The only unbiased way of *scheduling* processes in ABM is to randomize all sequences using a [pseudorandom number generator](https://en.wikipedia.org/wiki/Pseudorandom_number_generator). This technique is also used to create variation within a population of agents or between the global conditions of simulation runs, which is accomplished by drawing the values of variables from probability distributions, defined through *hyperparameters* (*e.g.*, drawing the age of individuals in a classroom from a normal distribution defined by two parameters, `age_mean` and `age_standardDeviation`).

---
### ABM in archaeology

particularities of ABM in archaeology

---
### SES framework

the behaviour-environment balance

---
### Modelling 'steps'

Modelling with ABM can be divided into a series of steps, most of which are identified by the community of practitioners as either normative or recommended phases of model development. These are: 

- *definition* of research question and phenomenon, 
- *design*, 
- *implementation*,
- *verification*
- *Validation*, which is considered a fifth step by most of the modeling literature, is regarded here as an extra, lengthy process, often separable from the tasks involved in creating and exploring a model.
  
Furthermore, a few of us also like to highlight two additional steps that are not normally acknowledged: 
- *understanding* the model. and 
- *documenting* the model. In explaining all modeling steps, we keep instructions general enough for them to be valid when dealing with any platform or programming language.


### Modelling '(mis)steps'

However, building an ABM model is in practice a process that is significantly more complicated than the steps listed above. There are many shortcuts, such as finding a model or piece of code that can save months of work, but, more often, there are obstacles, fallbacks and failures that test ABM modellers and the teams of researchers working with them. Some modellers (possibly myself included) have characterized this as an 'reiterative' process, often drawing diagrams where these steps are shown well-planned cycles. It might be more exact, however, to loose the walking metaphor altogether. 

The first problematic situation that comes to mind are, of course, the "technical issues". Developing ABM models requires a set of skills that are rare and hard to obtain and maintain, meanwhile doing other research tasks. Probably the most prominent skill of a modeller is programming, which involves both conceptual abstraction and certain agility with the software being used. The latter is made even more relevant when the software used is poorly documented or requires a special setup upon installation. This is certainly the first entry toll of the ABM community for researchers coming from humanities and social sciences. Still, the hardships on this side are normally surpassable with continuous training, support from more experience modellers, and choosing the right software.

Unfortunately, there are issues in ABM that go deeper than code and software. For example, during the model design process, researchers might need to ask inconvenient and apparently trivial questions about the phenomena represented, which raise an unexpected amount of controversy and doubt, and can even challenge some of the core assumptions behind a study. In archaeology, this may come as aspects that are considered out of the scope of empirical research, due to the limiting nature of archaeological data in comparison to disciplines that focus on contemporary observations (e.g. anthropology, sociology, geography). Should an archaeological ABM model include mechanisms that cannot be 'validated' by archaeological data (at least not in the same sense of experimental sciences)? This is probably the biggest unresolved question in this field and possibly the one most responsible of hindering the use of ABM in archaeology.

All of these complications can be considered problems as well as opportunities, depending on if and how they are eventually resolved. In some cases, the complication will present a new idea or approach while, in other cases, dealing with it might cost valuable time and delay the research outcomes beyond any external deadlines (e.g. project funding, dissertation submission). The tutorial below is presented in the spirit of safeguarding modellers in training from being stopped by some of these obstacles, which they may encounter when pursuing their own research agendas using ABM.

---
### References

**_Introductions to ABM in archaeology_**

> Romanowska, Iza. 2021. Agent-Based Modeling for Archaeology. Electronic. SFI Press. https://doi.org/10.37911/9781947864382.

> Romanowska, Iza, Stefani A. Crabtree, Kathryn Harris, and Benjamin Davies. 2019. ‘Agent-Based Modeling for Archaeologists: Part 1 of 3’. Advances in Archaeological Practice 7 (2): 178–84. https://doi.org/10.1017/aap.2019.6.

> Davies, Benjamin, Iza Romanowska, Kathryn Harris, and Stefani A. Crabtree. 2019. ‘Combining Geographic Information Systems and Agent-Based Models in Archaeology: Part 2 of 3’. Advances in Archaeological Practice 7 (2): 185–93. https://doi.org/10.1017/aap.2019.5.

> Crabtree, Stefani A., Kathryn Harris, Benjamin Davies, and Iza Romanowska. 2019. ‘Outreach in Archaeology with Agent-Based Modeling: Part 3 of 3’. Advances in Archaeological Practice 7 (2): 194–202. https://doi.org/10.1017/aap.2019.4.

> Graham, Shawn, Neha Gupta, Jolene Smith, Andreas Angourakis, Andrew Reinhard, Ellen Ellenberger, Zack Batist, et al. n.d. ‘4.4 Artificial Intelligence in Digital Archaeology’. In The Open Digital Archaeology Textbook. Ottawa: ECampusOntario. https://o-date.github.io/draft/book/artificial-intelligence-in-digital-archaeology.html.

> Breitenecker, Felix, Martin Bicher, and Gabriel Wurzer. 2015. ‘Agent-Based Simulation in Archaeology: A Characterization’. In Agent-Based Modeling and Simulation in Archaeology, edited by Gabriel Wurzer, Kerstin Kowarik, and Hans Reschreiter, 53–76. Springer, Cham. https://doi.org/10.1007/978-3-319-00008-4_3.

> Cegielski, Wendy H., and J. Daniel Rogers. 2016. ‘Rethinking the Role of Agent-Based Modeling in Archaeology’. Journal of Anthropological Archaeology 41 (March): 283–98. https://doi.org/10.1016/J.JAA.2016.01.009.


**_Application examples of ABM in archaeology_**

> Rubio Campillo, Xavier, Jose María Cela, and Francesc Xavier Hernàndez Cardona. 2012. ‘Simulating Archaeologists? Using Agent-Based Modelling to Improve Battlefield Excavations’. Journal of Archaeological Science 39 (2): 347–56. https://doi.org/10.1016/j.jas.2011.09.020.

> Premo, L. S. 2006. ‘Agent-Based Models as Behavioral Laboratories for Evolutionary Anthropological Research’. Arizona Anthropologist 17: 91–113.

> Madella, Marco, Bernardo Rondelli, Carla Lancelotti, Andrea L. Balbo, Débora Zurro, Xavier Rubio Campillo, and Sebastian Stride. 2014. ‘Introduction to Simulating the Past’. Journal of Archaeological Method and Theory 21 (2): 251–57. https://doi.org/10.1007/s10816-014-9209-8.

> Angourakis, Andreas, Matthieu Salpeteur, Verònica Martínez Ferreras, Josep Maria Gurt Esparraguera, Verònica Martínez Ferreras, and Josep Maria Gurt Esparraguera. 2017. ‘The Nice Musical Chairs Model: Exploring the Role of Competition and Cooperation Between Farming and Herding in the Formation of Land Use Patterns in Arid Afro-Eurasia’. Journal of Archaeological Method and Theory 24 (4): 1177–1202. https://doi.org/10.1007/s10816-016-9309-8.


**_On the ODD protocol_**

> Grimm, Volker, Uta Berger, Finn Bastiansen, Sigrunn Eliassen, Vincent Ginot, Jarl Giske, John Goss-Custard, et al. 2006. ‘A Standard Protocol for Describing Individual-Based and Agent-Based Models’. Ecological Modelling 198 (1–2): 115–26. https://doi.org/10.1016/J.ECOLMODEL.2006.04.023.

> Grimm, Volker, Uta Berger, Donald L. DeAngelis, J. Gary Polhill, Jarl Giske, and Steven F. Railsback. 2010. ‘The ODD Protocol: A Review and First Update’. Ecological Modelling 221 (23): 2760–68. https://doi.org/10.1016/J.ECOLMODEL.2010.08.019.

> Müller, Birgit, Friedrich Bohn, Gunnar Dreßler, Jürgen Groeneveld, Christian Klassert, Romina Martin, Maja Schlüter, Jule Schulze, Hanna Weise, and Nina Schwarz. 2013. ‘Describing Human Decisions in Agent-Based Models – ODD + D, an Extension of the ODD Protocol’. Environmental Modelling & Software 48 (October): 37–48. https://doi.org/10.1016/J.ENVSOFT.2013.06.003.

**_External bibliography of ABM in archaeology_**

https://github.com/ArchoLen/The-ABM-in-Archaeology-Bibliography

**_Other resources for learning ABM_**

>Hart, Vi, and Nicky Case. n.d. ‘Parable of the Polygons’. Parable of the Polygons. Accessed 24 May 2022. http://ncase.me/polygons.

> Izquierdo, Luis R., Segismundo S. Izquierdo, and William H. Sandholm. 2019. Agent-Based Evolutionary Game Dynamics. https://wisc.pb.unizin.org/agent-based-evolutionary-game-dynamics/.


---
---
## Tutorial

!!!INTRO

Case study: 

**Settlement interaction and the emergence of hierarchical settlement structures in Prepalatial south-central Crete** (Paliou & Bevan 2016)

!!! Brief Summary and mention of regression approach used in paper

**Main Reference**

> Paliou, Eleftheria, and Andrew Bevan. 2016. ‘Evolving Settlement Patterns, Spatial Interaction and the Socio-Political Organisation of Late Prepalatial South-Central Crete’. Journal of Anthropological Archaeology 42 (June): 184–97. https://doi.org/10.1016/j.jaa.2016.04.006.

**Useful complementary references**

> Angourakis, Andreas, Jennifer Bates, Jean-Philippe Baudouin, Alena Giesche, Joanna R. Walker, M. Cemre Ustunkaya, Nathan Wright, Ravindra Nath Singh, and Cameron A. Petrie. 2022. ‘Weather, Land and Crops in the Indus Village Model: A Simulation Framework for Crop Dynamics under Environmental Variability and Climate Change in the Indus Civilisation’. Quaternary 5 (2): 25. https://doi.org/10.3390/quat5020025.

> Wilkinson, Tony J., John H. Christiansen, Jason Alik Ur, M. Widell, and Mark R. Altaweel. 2007. ‘Urbanization within a Dynamic Environment: Modeling Bronze Age Communities in Upper Mesopotamia’. American Anthropologist 109 (1): 52–68. https://doi.org/10.1525/aa.2007.109.1.52.

---

### Block A

#### Definition of domain/phenomenon/question

!!! TO DO: formation of settlement hierarchical structures

#### Conceptual model 



#### NOTE #1: models as reference



#### Getting to know NetLogo

#### NOTE #2: other platforms/languages

#### Prototyping

---
### Block B

#### NetLogo basics

>NOTE: In the explanation below I'm using `<UPPERCASE_TEXT>` to express the positions in the code to be filled by the name of entities, variables, and other elements, depending on the context. For instance, `<COLOR> <FRUIT>` would represent many possible phrases, such as "red apple", "brown kiwi", etc. 

**Console interaction**

As a preamble, important to anyone without previous experiences with programming languages, the very first thing one can do in NetLogo is give oneself a bit of encouragement. In the **NetLogo interface**, go to the bottom area named **'Command Center'** and type the following in the empty field on the right of **'observer>'** and press Enter:

```NetLogo
You can do it!
```

The console prints:

```
ERROR: Nothing named YOU has been defined. 
```

Oops! NetLogo still doesn't know "you". Or is it that it cannot *understand* you? Well let us get you two properly introduced...

**Entities**

The (real) first thing one should learn about NetLogo, and most agent-based modeling systems, is that it handles *mainly* two types of entities/agents: `patches`, cells of a square grid, and `turtles`, which are proper "agents" (i.e., mobile, autonomous entities). Both entities have *primitives* (built-in, default properties), some of which can be modified by processes in your model. For example, you can't modify the position of a patch, but you can change its filling color.

![Figure 2 in Izquierdo et al. 2019](https://wisc.pb.unizin.org/app/uploads/sites/28/2018/09/the-netlogo-world.png)*NetLogo world and entities (Figure 2 in Izquierdo et al. 2019)*

As seen in the figure above, NetLogo also includes a third type of entity, `links`, which has the particularity of describing a connection between two `turtles` and thus not having specific spatial coordinates of their own. We will deal with links later on, but for now we focus on the other entities, which are more commonly used in models.

All `patches` and `turtles` can be identified individually through primitives. Turtles have a unique numerical identifier (`who`) that is assigned automatically upon the creation of the turtle. Patches, in turn, have an unique combination of x and y integer coordinates in 2D space (`pxcor` and `pycor`), as they occupy each a single position in a grid (see **Grid**). To reference a specific turtle or patch:

```NetLogo
turtle <WHO_NUMBER>
patch <PXCOR> <PYCOR>
```

NetLogo allows you to define types of `turtles` as if it where a primitive, declarings its name as a `breed`:

```NetLogo
breed [<BREED_1_NAME_PLURAL> <BREED_1_NAME_SINGULAR>]

breed [<BREED_2_NAME_PLURAL> <BREED_2_NAME_SINGULAR>]
```

We can then use the plural or singular form of the `breed` name directly, instead of referring to the generic `turtles`.

```NetLogo
<BREED_1_NAME_PLURAL> <WHO_NUMBER>
```

This is useful, of course, when there are more the one `breed`to be defined, so that they are easily distinguished and inteligible in the code.

Last, we should keep in mind that `turtles` can be created and destroyed on-the-fly during simulations, while `patches` are created in the background upon initialisation, according to the model settings (e.g. grid dimensions), but never destroyed during simulation runs.

See NetLogo's documentation on agents for further details (https://ccl.northwestern.edu/netlogo/docs/programming.html#agents).

**Variables**

The most fundamental elements of NetLogo, as in any programming language, is variables. To assign a value to a variable we use the general syntaxis or code structure:

```NetLogo
set <VARIABLE_NAME> <VALUE>
```

While variable names are fragments of contiguous text following a naming convention (*e.g.* `my-variable`, `myVariable`, `my_variable`, etc.), values can be of the following data types:

- Number (*e.g.*, `1`, `4.5`, `1E-6`)
- Boolean (*i.e.*, `true`, `false`)
- String (effectively text, but enclosed by quote marks: *e.g.*, `"1"`, `"my value"`)
- `turtles`, `patches` (*i.e.*, NetLogo's computation entities; see **Entities**)
- AgentSet (a set of either `turtles` or `patches`; see **Entities**)
- List (a list enclosed in squared brakets with values of any kind separated by spaces: *e.g.*, `[ "1" 1 false my-agents-bunch ["my value" true 4.5] ]`)

Before we assign a value to a variable, we must declare its scope and name, though not its data type, which is only defined when assigning an specific value. Variable declaration is typically done at the first section of a model script and its exact position will depend on if it is stored globally or inside entities. These types of declarations follow their own structures:

```NetLogo
globals [ <GLOBAL_VARIABLE_NAME> ]

turtles-own [ <TURTLE_VARIABLE_NAME> ]

<BREED_1_NAME_PLURAL>-own
[ 
  <BREED_1_VARIABLE_1_NAME>
  <BREED_1_VARIABLE_2_NAME>
]

patches-own [ <PATCHES_VARIABLE_NAME> ]
```

As an exception to this general rule, variables can also be declared "locally" using the following syntaxis:

```NetLogo
let <VARIABLE_NAME> <VALUE>
```

As in other programming languages, having a variable declared locally means it is inside a temporary computation environment, such as a procedure (see below). Once the environment is closed, the variable is automatically discarded in the background.

**Expressing equations**

As we will see examples further on, the values of variables can be transformed in different ways, using different syntaxis, depending on their type. Possibly the most straightforward case is to perform basic arithmetic operations over numerical variables, expressing equations. These can be writen using the special characters normally used in most programming languages (`+`, `-`, `*`, `/`, `(`, etc.):

```NetLogo
set myVariable (2 + 2) * 10 / ((2 + 2) * 10)
```

Notice that arithmetic symbols and numbers must be separated by spaces and that the order of operations can be structured using parentheses.

To help you read expressions that hold several operations, NetLogo allow line breaks, as long as these are placed after an operator (not a variable or value). The best and safer practice for this is to use parentheses abundantly to ensure the right sequence of operations is performed:

```NetLogo
set myVariable (
  (
    (2 + 2) * 
    10
  ) / (
    (2 + 2) * 
    10
  )
)
```

Additionally, as proper equations, such expressions in NetLogo will also accept variables names representing their current value. Equations can then serve to create far reaching dependencies between different parts of the model code:

```NetLogo
set myVariable 2
set myOtherVariable 10

<...>

let myTemporaryVariable 2 * myVariable * myOtherVariable

set myVariable myTemporaryVariable / myTemporaryVariable
```

**Procedures**

In NetLogo, any action we want to perform, that is not manually typed in the console, must be enclosed within a procedure that is declared in the model script (the text in **'Code'** tab in the user interface). Similarly to 'functions' or 'methods' in other programming languages, a procedure is the code scripted inside the following structure:

```NetLogo
to <PROCEDURE_NAME>
  <PROCEDURE_CODE>
end
```

Any procedure can be executed by typing `<PROCEDURE_NAME>` + Enter in the NetLogo's console at the bottom of the 'Interface' tab. The "Hello World" program, a typical minimum exercise when learning a programming language, correspond to the following procedure `hello-world`:

```NetLogo
to hello-world
  print "Hello World!"
end
```

which generates the following "prints" in the console:

```
observer> hello-world
Hello World!
```

Procedures are particularly useful to group and enclose a sequence of commands that are semantically connected for the programmer. For example, the following procedure declares a temporary (local) variable, assigns to it a number as value, and prints it in the console:

```NetLogo
to set-it-and-show-me
  let thisVariableOfMine 42
  print thisVariableOfMine
end
```

Procedures can then be used elsewhere by writing its name (more complications to come). A procedure can be included as a step in another procedure: 

```NetLogo
to <PROCEDURE NAME>
  <PROCEDURE_1>
  <PROCEDURE_2>
  <PROCEDURE_3>
  ...
end
```

NetLogo's interface editor allows us to create buttons that can execute one or multiple procedures (or even a snippet of *ad hoc* code). The interface system is quite straightforward. First, at the top of the interface tab, click "Add" and select a type of element in the drop-down list. Click anywhere in the window below to place it. Select it with click-dragging or using the "Select" option in the right-click pop-up menu. You can edit the element by selecting "Edit", also in the right-click pop-up menu. For any doubts on how to edit the interface tab, please refer to NetLogo's documentation (https://ccl.northwestern.edu/netlogo/docs/interfacetab.html).

**Logic bifurcation: `if` and `ifelse`**

>The code exemplifies how to create conditional rules according to predefined general conditions using if/else statements, which in NetLogo can be written as `if` or `ifelse`:
```NetLogo
if (<CONDITION_1_IS_TRUE>)
[
  <DO_ACTION_A>
]

ifelse (<CONDITION_2_IS_TRUE>)
[
  <DO_ACTION_B>
]
[
  <DO_ACTION_C>
]
```
>In this step, we are ordering patches to paint themselves green or blue depending on if their distance to the center is less than a given value).
```NetLogo
ifelse (distance centralPatch < minDistOfLandToCentre)
[
  set pcolor blue ; water
]
[
  set pcolor green ; land
]
```

**Entities with variables, logic operations, and procedures**

You can `ask` all or any subset of entities to perform specific commands by folowing the structure:

```NetLogo
ask <ENTITIES>
[ 
  <DO_SOMETHING>
]
```

Commands inside the `ask` structure can be both direct variable operations and procedures. For instance:

```NetLogo
ask <BREED_1_NAME_PLURAL>
[ 
  set <BREED_1_VARIABLE_2> <VALUE>
  <PROCEDURE_1>
  <PROCEDURE_2>
  <PROCEDURE_3>
]
```

However, all variables referenced inside these structures must be properly related to their scope, following NetLogo's syntax. For example, an agent is only able to access the variable in another agent if it we use the folowing kind of structure:

```NetLogo
ask <BREED_1_NAME_PLURAL>
[ 
  set <BREED_1_VARIABLE_2> of  <VALUE>
]
```

It is possible to select a subset of any set of entities through logic clauses to be checked separately for each individual entity. For example, to get all agents with a certain numeric property greater than a given threshold:

```NetLogo
<TYPE_NAME_PLURAL> with [ <VARIABLE_NAME_1> > <THRESHOLD> ]
```

As a summary minimum example, running the folowing script in NetLogo will define a type of turtle named `my-chatty-agents` (plural)

**Grid**

One should spend some time understanding the grid structure and associated syntaxis. It is recommendable to consult the "settings" pop-up window in the "interface tab":

![The settings pop-up window in NetLogo](https://ccl.northwestern.edu/netlogo/docs/images/interfacetab/settings.gif)*The settings pop-up window in NetLogo*

The default configuration is a 33x33 grid with the position (0,0) at the center. Both dimensions and center can be easily edited for each particular model. Moreover, we can specify agents behavior at the borders by ticking the "wrap" options. Wrapping the world limits means that, for instance, under the default setting mentioned above, the position (-16,0) is adjacent to (16,0). In the console, we can "ask" the patch at (-16,0) to print its distance to the patch at (16,0), using the primitive function `distance` (https://ccl.northwestern.edu/netlogo/docs/dictionary.html#distance):

```
observador> ask patch -16 0 [ print distance patch 16 0 ]
1
```

Wrapping one dimension represents a cylindrical surface while wrapping two depicts a strange toroidal object (Donut!). Although this aspect is relatively hidden among the options, it can have great importance if spatial relations play any part in a model. So if you want your grid to represent a geographical map, make sure to untick the wrapping features.

**Commenting code**

Annotations or comments (i.e., text that should be ignored when executing the code) can be added to the code by using the structure:

```NetLogo
<CODE>
; <FREE_TEXT>
<CODE>
```

or

```NetLogo
<CODE> ; <FREE_TEXT>
```

**Dictionary**

One of the most useful resources of NetLogo's documentation is the *dictionary* that can be accessed in the "Help" menu. This is true at any moment throughout your learning curve; even when you know all *primitives* and built-in functions by heart. Moreover, all documentation is present with any copy of NetLogo, so it is fully available offline. 

The dictionary is particularly useful whenever you are learning by example, as in our case. For instance, regarding the earlier mention of `distance`, you could have searched it in the dictionary directly. Whenever you find yourself reading NetLogo code with violet or blue words that you do not understand, take the habit of searching them in NetLogo's *dictionary*.

For **more information** consult [NetLogo Programming Guide](https://ccl.northwestern.edu/netlogo/docs/programming.html).

#### Test-drive: drawing a terrain with code

**Drawing a blue circle**

The whole code is kept short so these aspects can be better observed, investigated, and assimilated:
```NetLogo
to create-map

  ask patches [

    ; set central patch
    let centralPatch patch 0 0

    ; set minimum distance to centre depending on world width
    let minDistOfLandToCentre round (0.5 * (world-width / 2))

    ifelse (distance centralPatch < minDistOfLandToCentre)
    [
      set pcolor blue ; water
    ]
    [
      set pcolor green ; land
    ]

  ]

end
 ```


#### Verification-refactoring cycle

#### Modularity and re-use 

#### NOTE #3: where to find modules

NetLogo Modelling Commons, CoMSES, NASSA

#### Exploring alternative and additional designs

---
### Block C

#### Integrating spatial data as input

The NetLogo default installation includes an extension to support GIS that can be used by adding the following to the first section of your script:

```NetLogo
extensions [ gis ]
```

This extension allows you to perform a variety of GIS operations and to connect patch and turtle behaviour to data expressed in GIS files, supporting both vector and raster. The description of its contents can be found here: https://ccl.northwestern.edu/netlogo/docs/gis.html

In this tutorial, we will only reference a few of the aspects of GIS in NetLogo. You will find useful 

#### Integrating time-series data as input

#### NOTE #4: degrees of model calibration

#### Formating and exporting output data

#### Strategies for model 'validation'

