# Programs

This document describes the structure and content of Reach _programs_,
including their syntactic forms, the standard library, and the standards
of valid programs.

> Get language support for Reach in your editor by visiting \[missing\].

The rest of this section is structured according to the contexts of the
different parts of a Reach program, as follows:

* Validity describes what is meant by the term valid in Reach.

* Modules describes the top-level structure of Reach module.

* Steps describes the structure of Reach steps.

* Local Steps describes the structure of Reach local steps.

* Consensus Steps describes the structure of Reach consensus steps.

* Computations describes the common structure of Reach computations
  shared by all contexts.

Figure 1 shows the relationship between the modes of a Reach
application.


Figure 1: The modes of a Reach application

## 1. Validity

Reach imposes further restrictions on syntactically well-formed
programs. These restrictions are described throughout this manual using
the term _valid_ to refer to constructions that obey the restrictions,
and the term _invalid_ to refer to constructions that do not obey them.

It is always invalid to use a value with an operation for which it is
undefined. For example, 1 + true is invalid. In other words, Reach
enforces a static type discipline.

### 1.1. Security levels and scope

The text of Reach program is public knowledge to all participants.
However, any value that comes from an interaction expression is a
_secret_ which only that participant knows. Furthermore, any values
derived from secret values are also secret. A value, X, is considered
derived from another, Y, if the value of Y is provided to a primitive
operation to arrive at X, or if Y is used as part of a conditional that
influences the definition of X. Secrets can only be made public by using
the declassify primitive.

When secret values are bound to an identifier within a local step, the
identifier name MUST be prefixed by an underscore (\_).

When public values are bound to an identifier, regardless of context,
the identifier name MUST NOT be prefixed by an underscore (\_).

Consequently, identifiers which appear inside of a function definition
or arrow expression MAY be prefixed by an underscore. This will cause a
compiler error if any value bound to that identifier is public.

## 2. Modules

A Reach _source file_ is a textual file which specifies a Reach module.
It is traditionally given the file extension `rsh`, e.g. `"dao.rsh"`.

A _module_ starts with reach 0.1; followed by a sequence of imports and
identifier definitions. A module can only be compiled or used if it
contain one or more exports.

> See the guide section on versions to understand how Reach uses version
> numbers like this.

### 2.1. Statements

Any statements valid for a computation are valid for a module. However,
some additional statements are allowed.

#### 2.1.1. `export`

Module-level identifier definitions may be _export_ed by writing  export
in front of them. For example, export const x = 1; export const \[a, b,
...more\] = \[ 0, 1, 2, 3, 4 \]; export function add1\(x) { return x +
1; };  are valid exports.

Module-level identifiers may also be exported after the fact, and may be
renamed during export. For example:

const w = 2; const z = 0; export {w, z as zero};

Identifiers from other modules may be re-exported (and renamed), even if
they are not imported in the current module. For example:

export {u, x as other\_x} from ./other-module.rsh;

An exported identifier in a given module may be imported by other
modules.

Exports are also exposed to the frontend via getExports. Functions are
only exposed if they are typed, that is, if they are constructed with
is.

#### 2.1.2. `import`

import games-of-chance.rsh;

When a module, `X`, contains an _import_, written import "LIB.rsh";,
then the path `"LIB.rsh"` must resolve to another Reach source file. The
exports from the module defined by `"LIB.rsh"` are included in the set
of bound identifiers in `X`.

import {flipCoin, rollDice as d6} from games-of-chance.rsh;

Import statements may limit or rename the imported identifiers.

import \* as gamesOfChance from games-of-chance.rsh;

Imports may instead bind the entire module to a single identifier, which
is an object with fields corresponding to that module’s exports.

Import cycles are invalid.

The path given to an import may **not** include `..` to specify files
outside the current directory **nor** may it be an absolute path.

It **must** be a relative path, which is resolved relative to the parent
directory of the source file in which they appear.

### 2.2. Expressions

Any expressions valid for a computation are valid for a module. However,
some additional expressions are allowed.

#### 2.2.1. `Reach.App`

export const main =   Reach.App\({}, \[Participant\("A", {displayResult:
Fun\(Int, Null)})\], \(A) => {     const result = 0;     A.only\(\(\) =>
{ interact.displayResult\(result); })     return result;   });

_Reach.App_ is a function which accepts three arguments: options,
applicationArgs, and program.

The options must be an object. It supports the following options:

```racket
deployMode         constructor (default) or firstMsg Determines whether contract should be deployed independently            
                                                     (constructor) or as part of the first publication (firstMsg). If        
                                                     deployed as part of the first publication, then the first publication   
                                                     must precede all uses of wait and .timeout. See the guide on deployment 
                                                     modes for a discussion of why to choose a particular mode.              
                                                                                                                             
verifyArithmetic   true or false (default)           Determines whether arithmetic operations automatically introduce static 
                                                     assertions that they do not overflow beyond UInt.max. This defaults to  
                                                     false, because it is onerous to verify. We recommend turning it on      
                                                     before final deployment, but leaving it off during development. When it 
                                                     is false, connectors will ensure that overflows do not actually occur on
                                                     the network.                                                            
                                                                                                                             
verifyPerConnector true or false (default)           Determines whether verification is done per connector, or once for a    
                                                     generic connector. When this is true, then connector-specific constants,
                                                     like UInt.max, will be instantiated to literal numbers. This            
                                                     concretization of these constants can induce performance degradation in 
                                                     the verifier.                                                           
                                                                                                                             
connectors         [ETH, ALGO] (default)             A tuple of the connectors that the application should be compiled for.  
                                                     By default, all available connectors are chosen.                        
```

The applicationArgs argument is a tuple of application arguments.

The program argument must be a syntactic arrow expression. The arguments
to this arrow must match the number and order of applicationArgs. The
function body is the program to be compiled. It specifies a step, which
means its content is specified by Steps. When it returns, it must be in
a step, as well; which means that its content cannot end within a
consensus step.

If the result of Reach.App is eventually bound to an identifier that is
exported, then that identifier may be a target given to the compiler, as
discussed in the section on usage.

#### 2.2.2. Application Arguments

An _application argument_ is used for declaring the components of a
Reach DApp. These components are either participants or views.

**—**

A participant and participant class may be declared with

Participant\(participantName, participantInteractInterface)

and

ParticipantClass\(participantName, participantInteractInterface)

respectively.

participantName is a string which indicates the name of the participant
function in the generated backend code. Each participantName must be
unique.

participantInteractInterface is a _participant interact interface_, an
object where each field indicates the type of a function or value which
must be provided to the backend by the frontend for interacting with the
participant.

**—**

View\(NFT, { owner: Address })

A view is defined with View\(viewName, viewInterface), where viewName is
a string that labels the view and viewInterface is an object where each
field indicates the type of a function or value provided by the contract
associated with the specified DApp. These views are available in
frontends via the ctc.getViews function. In the DApp, the result of this
application argument is referred to as a view object.

## 3. Steps

A Reach step occurs in the body of Reach.App or in the continuation of a
commit statement. It represents the actions taken by each of the
participants in an application.

### 3.1. Statements

Any statements valid for a computation are valid for a step. However,
some additional statements are allowed.

#### 3.1.1. `only` and `each`

Alice.only\(\(\) => {   const pretzel = interact.random\(\); });

A local step statement is written PART.only\(\(\) => BLOCK), where PART
is a participant identifier and BLOCK is a block. Within BLOCK, PART is
bound to the address of the participant. Any bindings defined within the
block of a local step are available in the statement’s tail as new local
state. For example,

Alice.only\(\(\) => {   const x = 3; }); Alice.only\(\(\) => {   const y
= x + 1; });

is a valid program where Alice’s local state includes the private values
x (bound to 3) and y (bound to 4). However, such bindings are ​_not_​
consensus state, so they are purely local state. For example,

Alice.only\(\(\) => {   const x = 3; }); Bob.only\(\(\) => {   const y =
x + 1; });

is an invalid program, because Bob does not know x.

**—**

each\(\[Alice, Bob\], \(\) => {   const pretzel = interact.random\(\);
});

An _each_ local step statement can be written as each\(PART\_TUPLE \(\)
=> BLOCK), where PART\_TUPLE is a tuple of participants and BLOCK is a
block. It is an abbreviation of many local step statements that could
have been written with only.

#### 3.1.2. Pay Amounts

A _pay amount_ is either:

* An integer, denoting an amount of network tokens; or,

* A tuple of token amounts.

A _token amount_ is either:

* An integer, denoting an amount of network tokens; or,

* A tuple with two elements, where the first is an integer, denoting an
  amount of non-network tokens, and the second is Token, specifying a
  particular non-network token.

For example, these are all pay amounts: 0 5 \[ 5 \] \[ 5, \[ 2, gil \]
\] \[ \[ 2, gil \], 5 \] \[ 5, \[ 2, gil \], \[ 8, zorkmids \] \]

It is invalid for a pay amount to specify an amount of tokens multiple
times. For examples, these are invalid pay amounts: \[ 1, 2 \] \[ \[2,
gil\], \[1, gil\] \]

The ordering of a pay amount is only significant when used within a fork
statement or parallel reduce statement that specifies a paySpec. In this
case, payments are expected to be a tuple where the first element is an
integer pay amount, and the rest of the elements are token amount
tuples. The ordering of the token amount elements should match the
ordering in paySpec. For example, .paySpec\(\[tokA, tokB\])

will indicate that fork payments should be of the format:

\[ NETWORK\_TOKEN\_AMT, \[ amtA, tokA \], \[ amtB, tokB \] \]

#### 3.1.3. `publish`, `pay`, `when`, and `timeout`

Alice.publish\(wagerAmount)      .pay\(wagerAmount)
.timeout\(DELAY, \(\) => {        Bob.publish\(\);        commit\(\);
return false; });   Alice.publish\(wagerAmount)      .pay\(wagerAmount)
.timeout\(DELAY, \(\) => closeTo\(Bob, false));
Alice.publish\(wagerAmount)      .pay\(wagerAmount)
.timeout\(false);

A consensus transfer is written PART\_EXPR.publish\(ID\_0, ...,
ID\_n).pay\(PAY\_EXPR)..when\(WHEN\_EXPR).timeout\(DELAY\_EXPR, \(\) =>
TIMEOUT\_BLOCK), where PART\_EXPR is an expression that evaluates to a
participant or race expression, ID\_0 through ID\_n are identifiers for
PART’s public local state, PAY\_EXPR is a public expression evaluating
to a pay amount, WHEN\_EXPR is a public expression evaluating to a
boolean and determines if the consensus transfer takes place,
DELAY\_EXPR is a public expression that depends on only consensus state
and evaluates to a time delta represented by a natural number,
TIMEOUT\_BLOCK is a timeout block, which will be executed after
DELAY\_EXPR units of time have passed from the end of the last consensus
step without PART executing this consensus transfer. The continuation of
a consensus transfer statement is a consensus step, which is finalized
with a commit statement. The continuation of a timeout block is the same
as the continuation of the function the timeout occurs within.

> See the guide section on non-participation to understand when to use
> timeouts and how to use them most effectively.

The publish component exclusive-or the pay component may be omitted, if
either there is no publication or no transfer of network tokens to
accompany this consensus transfer. The when component may always be
omitted, in which case it is assumed to be true. publish or pay must
occur first, after which components may occur in any order. For example,
the following are all valid:

Alice.publish\(coinFlip);  Alice.pay\(penaltyAmount);
Alice.pay\(penaltyAmount).publish\(coinFlip);  Alice.publish\(coinFlip)
.timeout\(DELAY, \(\) => closeTo\(Bob, \(\) => exit\(\)\)\);
Alice.pay\(penaltyAmount)      .timeout\(DELAY, \(\) => {
Bob.publish\(\);        commit\(\);        exit\(\); });
Alice.publish\(bid).when\(wantsToBid);

The timeout component must be included if when is not statically true.
This ensures that your clients will eventually complete the program. If
a consensus transfer is a guaranteed race between non-class participants
and a participant class that ​_may_​ attempt to transfer (i.e. when is
not statically false), then a timeout may be explicitly omitted by
writing .timeout\(false).

.throwTimeout may be used in place of .timeout. It accepts a DELAY\_EXPR
and an EXPR, which will be thrown if a timeout should occur. If an EXPR
is not provided, then null will be thrown. If a consensus transfer uses
.throwTimeout, it must be within a try statement.

If a consensus transfer specifies a single participant, which has not
yet been fixed in the application and is not a participant class, then
this statement does so; therefore, after it the PART may be used as an
address.

If a consensus transfer specificies a single participant class, then all
members of that class will attempt to perform the transfer, but only one
will succeed.

A consensus transfer binds the identifiers ID\_0 through ID\_n for all
participants to the values included in the consensus transfer. If an
existing participant, not included in PART\_EXPR, has previously bound
one of these identifiers, then the program is not valid. In other words,
the following program is not valid:

Alice.only\(\(\) => {  const x = 1; }); Bob.only\(\(\) => {  const x =
2; }); Claire.only\(\(\) => {  const x = 3; }); race\(Alice,
Bob).publish\(x); commit\(\);

because Claire is not included in the race. However, if we were to
rename Claire’s x into y, then it would be valid, because although Alice
and Bob both bind x, they participate in the race, so it is allowed. In
the tail of this program, x is bound to either 1 or 2.

#### 3.1.4. `fork`

fork\(\) .case\(Alice, \(\(\) => \({   msg: 19,   when:
declassify\(interact.keepGoing\(\)\) })),   \(\(v) => v),   \(v) => {
require\(v == 19);     transfer\(wager + 19).to\(this);     commit\(\);
exit\(\);   }) .case\(Bob, \(\(\) => \({   when:
declassify\(interact.keepGoing\(\)\) })),   \(\(\_) => wager),   \(\_)
=> {     commit\(\);      Alice.only\(\(\) =>
interact.showOpponent\(Bob));      race\(Alice, Bob).publish\(\);
transfer\(2 \* wager).to\(this);     commit\(\);     exit\(\);   })
.timeout\(deadline, \(\) => {   race\(Alice, Bob).publish\(\);
transfer\(wager).to\(this);   commit\(\);   exit\(\); });

A _fork statement_ is written:

fork\(\) .paySpec\(TOKENS\_EXPR) .case\(PART\_EXPR,   PUBLISH\_EXPR,
PAY\_EXPR,   CONSENSUS\_EXPR) .timeout\(DELAY\_EXPR, \(\) =>
TIMEOUT\_BLOCK);

where: TOKENS\_EXPR is an expression that evalues to a tuple of Tokens.
PART\_EXPR is an expression that evaluates to a participant;
PUBLISH\_EXPR is a syntactic arrow expression that is evaluated in a
local step for the specified participant and must evaluate to an object
that may contain a `msg` field, which may be of any type, and a `when`
field, which must be a boolean; PAY\_EXPR is an expression that
evaluates to a function parameterized over the `msg` value and returns a
pay amount; CONSENSUS\_EXPR is a syntactic arrow expression
parameterized over the `msg` value which is evaluated in a consensus
step; and, the timeout and throwTimeout parameter are as in an consensus
transfer.

If the `msg` field is absent from the object returned from
PUBLISH\_EXPR, then it is treated as if it were null.

If the `when` field is absent from the object returned from
PUBLISH\_EXPR, then it is treated as if it were true.

If the PAY\_EXPR is absent, then it is treated as if it were \(\_) => 0.

The .case component may be repeated many times.

The same participant may specify multiple cases. In this situation, the
order of the cases is significant. That is, a subsequent case will only
be evaluated if the prior case’s `when` field is false.

If the participant specified by PART\_EXPR is not already fixed (in the
sense of Participant.set), then if it wins the race, it is fixed,
provided it is not a participant class.

**—**

A fork statement is an abbreviation of a common race and switch pattern
you could write yourself.

The idea is that each of the participants in the case components do an
independent local step evaluation of a value they would like to publish
and then all race to publish it. The one that "wins" the race then
determines not only the value (& pay amount), but also what consensus
step code runs to consume the value.

The sample fork statement linked to the fork keyword is roughly
equivalent to: // We first define a Data instance so that each
participant can publish a // different kind of value const ForkData =
Data\({Alice: UInt, Bob: Null}); // Then we bind these values for each
participant Alice.only\(\(\) => {  const fork\_msg =
ForkData.Alice\(19);  const fork\_when =
declassify\(interact.keepGoing\(\)\); }); Bob.only\(\(\) => {  const
fork\_msg = ForkData.Bob\(null);  const fork\_when =
declassify\(interact.keepGoing\(\)\); }); // They race race\(Alice, Bob)
.publish\(fork\_msg)  .when\(fork\_when)  // The pay ammount depends on
who is publishing  .pay\(fork\_msg.match\( {    Alice: \(v => v),
Bob: \(\(\_) => wager) } ))  // The timeout is always the same
.timeout\(deadline, \(\) => {    race\(Alice, Bob).publish\(\);
transfer\(wager).to\(this);    commit\(\);    exit\(\); });   // We
ensure that the correct participant published the correct kind of value
require\(fork\_msg.match\( {    // Alice had previously published
Alice: \(v => this == Alice),    // But Bob had not.    Bob: \(\(\_) =>
true) } ));   // Then we select the appropriate body to run  switch
\(fork\_msg) {    case Alice: {      assert \(this == Alice);
require\(v == 19);      transfer\(wager + 19).to\(this);
commit\(\);      exit\(\); }    case Bob: {      Bob.set\(this);
commit\(\);       Alice.only\(\(\) => interact.showOpponent\(Bob));
race\(Alice, Bob).publish\(\);      transfer\(2 \* wager).to\(this);
commit\(\);      exit\(\); }  }

This pattern is tedious to write and error-prone, so the fork statement
abbreviates it for Reach programmers. When a participant specifies
multiple cases, the `msg` field of the participant will be wrapped with
an additional variant signifying what case was chosen.

#### 3.1.5. `wait`

wait\(AMOUNT);

A _wait statement_, written wait\(AMOUNT);, delays the computation until
AMOUNT time delta units have passed. It may only occur in a step.

#### 3.1.6. `exit`

exit\(\);

An _exit statement_, written exit\(\);, halts the computation. It is a
terminator statement, so it must have an empty tail. It may only occur
in a step.

### 3.2. Expressions

Any expressions valid for a computation are valid for a step. However,
some additional expressions are allowed.

#### 3.2.1. `race`

race\(Alice, Bob).publish\(bet);

A _race expression_, written race\(PARTICIPANT\_0, ...,
PARTICIPANT\_n);, constructs a participant that may be used in a
consensus transfer statement, such as publish or pay, where the various
participants race to be the first one to perform the consensus transfer.

Reach provides a shorthand, Anybody, which serves as a race between all
the participants.

> See the guide section on races to understand the benefits and dangers of
> using race.

#### 3.2.2. `unknowable`

unknowable\( Notter, Knower\(var\_0, ..., var\_N), \[msg\] )

A knowledge assertion that the participant Notter ​_does not_​ know the
results of the variables var\_0 through var\_N, but that the participant
Knower ​_does_​ know those values. It accepts an optional bytes
argument, which is included in any reported violation.

#### 3.2.3. `closeTo`

closeTo\( Who, after, nonNetPayAmt )

Has participant Who make a publication, then transfer the balance\(\)
and the non-network pay amount to Who and end the DApp after executing
the function after in a step. The nonNetPayAmt parameter should be a pay
amount. For example, when closing a program that uses a Token token, the
argument would be \[ \[balance\(tok), tok\] \]. The after and
nonNetPayAmt argument are optional.

## 4. Local Steps

A Reach local step occurs in the body of only or each statements. It
represents the actions taken by a single participant in an application.

### 4.1. Statements

Any statements valid for a computation are valid for a local step.

### 4.2. Expressions

Any expressions valid for a computation are valid for a local step.
However, some additional expressions are allowed.

#### 4.2.1. `this`

Inside of a local step, this refers to the participant performing the
step. This is useful when the local step was initiated by an each
expression.

#### 4.2.2. `interact`

interact.amount interact.notify\(handA, handB)
interact.chooseAmount\(heap1, heap2)

An _interaction expression_, written interact.METHOD\(EXPR\_0, ...,
EXPR\_n), where METHOD is an identifier bound in the participant
interact interface to a function type, and EXPR\_0 through EXPR\_n are
expressions that evaluates to the result of an interaction with a
frontend that receives the evaluation of the n expressions and sends a
value.

An interaction expression may also be written interact.KEY, where KEY is
bound in the participant interact interface to a non-function type.

An interaction expression may only occur in a local step.

#### 4.2.3. `assume`

assume\( claim, \[msg\] )

An assumption where claim evaluates to true with honest frontends. This
may only appear in a local step. It accepts an optional bytes argument,
which is included in any reported violation.

#### 4.2.4. `fail`

fail\(\)

is a convenience method equivalent to assume\(false). This may only
appear in a local step.

#### 4.2.5. `declassify`

declassify\( arg )

The _declassify_ primitive performs a declassification of the given
argument.

#### 4.2.6. `makeCommitment`

makeCommitment\( interact, x )

Returns two values, \[ commitment, salt \], where salt is the result of
calling interact.random\(\), and commitment is the digest of salt and x.
This is used in a local step before checkCommitment is used in a
consensus step.

## 5. Consensus Steps

A Reach consensus step occurs in the continuation of a consensus
transfer statement. It represents the actions taken by the consensus
network contract of an application.

### 5.1. Statements

Any statements valid for a computation are valid for a consensus step.
However, some additional statements are allowed.

#### 5.1.1. `commit`

commit\(\);

A _commit statement_, written commit\(\);, commits to statement’s
continuation as the next step of the DApp computation. In other words,
it ends the current consensus step and allows more local steps.

#### 5.1.2. `only` and `each`

`only` and `each` are allowed in consensus steps and are executed by
backends once they observe the completion of the consensus step (i.e.,
after the associated commit statement.)

#### 5.1.3. View Objects

vNFT.owner.set\(creator);

If VIEW is a _view object_, then its fields are the elements of the
associated view. Each of these fields are bound to an object with an
`set` method that accepts the function or value to be bound to that view
at the current step, and all steps dominated by the current step (unless
otherwise overridden.) If this function is not provided with an
argument, then the corresponding view is unset.

For example, consider the following program:

```racket
[view-steps/index.rsh](https://github.com/reach-sh/reach-lang/blob/master/examples/view-steps/index.rsh)
```

1    reach 0.1;  2      3    const Tlast = Maybe\(Address);  4    const
Ti = Maybe\(UInt);  5    const T = Tuple\(Tlast, Ti);  6      7
export const main =  8     Reach.App\({},  9      \[ Participant\(Alice,
{ checkView: Fun\(\[T\], Null) }), 10        Participant\(Bob, {}), 11
View\(Main, { last: Address, i: UInt }), 12      \], 13      \(A, B,
vMain) => { 14        const checkView = \(x) => 15          A.only\(\(\)
=> interact.checkView\(x)); 16     17        // The contract doesnt
exist yet, so no view 18        checkView\(\[Tlast.None\(\),
Ti.None\(\)\]\); 19     20        A.publish\(\); 21
vMain.i.set\(1); 22        vMain.last.set\(A); 23        // These views
are now visible 24        checkView\(\[Tlast.Some\(A), Ti.Some\(1)\]);
25        commit\(\); 26     27        // Block race of Alice and Bob
for Alice to observe the state 28        A.publish\(\); 29
commit\(\); 30     31        B.publish\(\); 32        vMain.i.set\(2);
33        vMain.last.set\(B); 34        if \( A != B ) { 35          //
The views above are visible 36          checkView\(\[Tlast.Some\(B),
Ti.Some\(2)\]); 37          commit\(\); 38        } else { 39
// Or, we overwrite them 40          vMain.i.set\(3); 41
vMain.last.set\(\); 42          checkView\(\[Tlast.None\(\),
Ti.Some\(3)\]); 43          commit\(\); 44        } 45     46
A.publish\(\); 47        // The contract doesnt exist anymore, so no
view 48        checkView\(\[Tlast.None\(\), Ti.None\(\)\]\); 49
commit\(\); 50     51        exit\(\); 52      });

In this program, the Reach backend calls the frontend interact function,
checkView with the expected value of the views at each point in the
program. The frontend compares that value with what is returned by \[
await ctc.getViews\(\).Main.last\(\),   await
ctc.getViews\(\).Main.i\(\) \]

When a view is bound to a function, it may inspect any values in its
scope, including linear state.

#### 5.1.4. `Participant.set` and `.set`

Participant.set\(PART, ADDR); PART.set\(ADDR);

After execution, the given participant is fixed to the given address. It
is invalid to attempt to .set a participant class. If a backend is
running for this participant and its address does not match the given
address, then it will abort. This may only occur within a consensus
step.

> \[missing\] is a good introductory project that demonstrates how to use
> this feature of Reach.

#### 5.1.5. `while`

var \[ heap1, heap2 \] = \[ 21, 21 \]; { const sum = \(\) => heap1 +
heap2; } invariant\(balance\(\) == 2 \* wagerAmount); while \( sum\(\) >
0 ) {   ....   \[ heap1, heap2 \] = \[ heap1 - 1, heap2 \];   continue;
}

A _while statement_ may occur within a consensus step and is written:

var LHS = INIT\_EXPR; BLOCK; // optional invariant\(INVARIANT\_EXPR);
while\( COND\_EXPR ) BLOCK

where LHS is a valid left-hand side of an identifier definition where
the expression INIT\_EXPR is the right-hand side, and BLOCK is an
optional block that may define bindings that use the LHS values which
are bound inside the rest of the while and its tail, and INVARIANT\_EXPR
is an expression, called the _loop invariant_, that must be true before
and after every execution of the block BLOCK, and if COND\_EXPR is true,
then the block executes, and if not, then the loop terminates and
control transfers to the continuation of the while statement. The
identifiers bound by LHS are bound within INVARIANT\_EXPR, COND\_EXPR,
BLOCK, and the tail of the while statement.

> Read about finding loop invariants in the Reach guide.

#### 5.1.6. `continue`

\[ heap1, heap2 \] = \[ heap1 - 1, heap2 \]; continue;

A _continue statement_ may occur within a while statement’s block and is
written:

LHS = UPDATE\_EXPR; continue;

where the identifiers bound by LHS are a subset of the variables bound
by the nearest enclosing while statement and UPDATE\_EXPR is an
expression which may be bound by LHS.

A continue statement is a terminator statement, so it must have an empty
tail.

A continue statement may be written without the preceding identifier
update, which is equivalent to writing

\[\] = \[\]; continue;

A continue statement must be dominated by a consensus transfer, which
means that the body of a while statement must always commit\(\); before
calling continue;. This restriction may be lifted in future versions of
Reach, which will perform termination checking.

#### 5.1.7. `parallelReduce`

const \[ keepGoing, as, bs \] =   parallelReduce\(\[ true, 0, 0 \])
.invariant\(balance\(\) == 2 \* wager)   .while\(keepGoing)
.case\(Alice, \(\(\) => \({     when:
declassify\(interact.keepGoing\(\)\) })),     \(\_) => {
each\(\[Alice, Bob\], \(\) => {         interact.roundWinnerWas\(true);
});       return \[ true, 1 + as, bs \]; })   .case\(Bob, \(\(\) => \({
when: declassify\(interact.keepGoing\(\)\) })),     \(\_) => {
each\(\[Alice, Bob\], \(\) => {         interact.roundWinnerWas\(false);
});       return \[ true, as, 1 + bs \]; })   .timeout\(deadline, \(\)
=> {     showOutcome\(TIMEOUT)();     race\(Alice, Bob).publish\(\);
return \[ false, as, bs \]; });

A _parallel reduce statement_ is written:

const LHS =   parallelReduce\(INIT\_EXPR)   .invariant\(INVARIANT\_EXPR)
.while\(COND\_EXPR)   .paySpec\(TOKENS\_EXPR)   .case\(PART\_EXPR,
PUBLISH\_EXPR,     PAY\_EXPR,     CONSENSUS\_EXPR)
.timeout\(DELAY\_EXPR, \(\) =>     TIMEOUT\_BLOCK);

The LHS and INIT\_EXPR are like the initialization component of a while
loop; and, the .invariant and .while components are like the invariant
and condition of a while loop; while the .case, .timeout, and .paySpec
components are like the corresponding components of a fork statement.

The .case component may be repeated many times.

The same participant may specify multiple cases; the order of the cases
is significant, just like in a fork statement.

`.timeRemaining`

When dealing with absolute deadlines in parallelReduce, there is a
common pattern in the TIMEOUT\_BLOCK to have participants race to
publish and return the accumulator. There is a shorthand,
.timeRemaining, available for this situation:

const \[ timeRemaining, keepGoing \] = makeDeadline\(deadline); const \[
x, y, z \] =   parallelReduce\(\[ 1, 2, 3 \])
.while\(keepGoing\(\)\)     ...     .timeRemaining\(timeRemaining\(\)\)

which will expand to:

.timeout\(timeRemaining\(\), \(\) => {
race\(...Participants).publish\(\);   return \[ x, y, z \]; })

`.throwTimeout`

.throwTimeout is a shorthand that will throw the accumulator as an
exception when a timeout occurs. Therefore, a parallelReduce that uses
this branch must be inside of a try statement. For example,

try {   const \[ x, y, z \] =     parallelReduce\(\[ 1, 2, 3 \])     ...
.throwTimeout\(deadline) } catch \(e) { ... }

will expand throwTimeout to:

.timeout\(deadline, \(\) => {   throw \[ x, y, z \]; })

**—**

A parallel reduce statement is essentially an abbreviation of pattern of
a while loop combined with a fork statement that you could write
yourself. This is an extremely common pattern in decentralized
applications.

The idea is that there are some values (the LHS) which after
intialization will be repeatedly updated uniquely by each of the racing
participants until the condition does not hold.

var LHS = INIT\_EXPR; invariant\(INVARIANT\_EXPR) while\(COND\_EXPR) {
fork\(\)   .case\(PART\_EXPR,     PUBLISH\_EXPR,     PAY\_EXPR,     \(m)
=> {       LHS = CONSENSUS\_EXPR\(m);       continue; })
.timeout\(DELAY\_EXPR, \(\) =>     TIMEOUT\_BLOCK); }

### 5.2. Expressions

Any expressions valid for a computation are valid for a consensus step.
However, some additional expressions are allowed.

#### 5.2.1. `this`

Inside of a consensus step, this refers to the address of the
participant that performed the consensus transfer. This is useful when
the consensus transfer was initiated by a race expression.

#### 5.2.2. `transfer`

transfer\(10).to\(Alice); transfer\(2, gil).to\(Alice);

A _transfer expression_, written transfer\(AMOUNT\_EXPR).to\(PART),
where AMOUNT\_EXPR is an expression that evaluates to an unsigned
integer, and PART is a participant identifier, performs a transfer of
network tokens from the contract to the named participant. AMOUNT\_EXPR
must evaluate to less than or equal to the balance of network tokens in
the contract account.

A transfer expression may also be written transfer\(AMOUNT\_EXPR,
TOKEN\_EXPR).to\(PART), where TOKEN\_EXPR is a Token, which transfers
non-network tokens of the specified type.

A transfer expression may only occur within a consensus step.

#### 5.2.3. `require`

require\( claim, \[msg\] )

A requirement where claim evaluates to true with honest participants.
This may only appear in a consensus step. It accepts an optional bytes
argument, which is included in any reported violation.

#### 5.2.4. `checkCommitment`

checkCommitment\( commitment, salt, x )

Makes a requirement that commitment is the digest of salt and x. This is
used in a consensus step after makeCommitment was used in a local step.

#### 5.2.5. Remote objects

const randomOracle =   remote\( randomOracleAddr, {     getRandom:
Fun\(\[\], UInt),   }); const randomVal =
randomOracle.getRandom.pay\(randomFee)();

A _remote object_ is representation of a foreign contract in a Reach
application. During a consensus step, a Reach computation may
consensually communicate with such an object via a prescribed interface.

A remote object is constructed by calling the remote function with an
address and an interface—an object where each key is bound to a function
type. For example: const randomOracle =   remote\( randomOracleAddr, {
getRandom: Fun\(\[\], UInt),   }); const token =   remote\( tokenAddr, {
balanceOf: Fun\(\[Address\], UInt),     transferTo: Fun\(\[UInt,
Addres\], Null),   });

Once constructed, the fields of a remote object represent those remote
contract interactions, referred to as _remote functions_. For example,
randomOracle.getRandom, token.balanceOf, and token.transferTo are remote
functions in the example.

A remote function may be invoked by calling it with the appropriate
arguments, whereupon it returns the specified output. In addition, a
remote function may be augmented with one of the following operations:

* REMOTE\_FUN.pay\(AMT) — Returns a remote function that receives a pay
  amount, AMT, ​_from_​ the caller when it is called.

* REMOTE\_FUN.bill\(AMT) — Returns a remote function that provides a pay
  amount, AMT, ​_to_​ the caller when it returns.

* REMOTE\_FUN.withBill\(\) — Returns a remote function that provides
  some number of network tokens and, possibly, non-network tokens ​_to_​
  the caller when it returns. The exact amount is returned from the
  invocation by wrapping the original result in a tuple.

  If the remote contract is not expected to return non-network tokens
  then a pair is returned, where the amount of network tokens received
  is the first element, and the original result is the second element.

  If the remote contract is expected to return non-network tokens then a
  triple is returned, where the amount of network tokens received is the
  first element, a tuple of the non-network tokens received is the
  second element, and the original result is the third element. If the
  caller expects to receive non-network tokens, they must provide a
  tuple of tokens as an argument to withBill. The ordering of tokens in
  the argument is reserved when returning the amounts received. For
  example,

  const \[ returned, \[gilRecv, zmdRecv\], randomValue \] =
  randomOracle.getRandom.pay\(stipend).withBill\(\[gil, zmd\])();

  might be the way to communicate with a random oracle that receives a
  conservative approximation of its actual cost and returns what it does
  not use, along with some amount of `GIL` and `ZMD`. This operation may
  not be used with REMOTE\_FUN.bill.

#### 5.2.6. Mappings: creation and modification

const bidsM = new Map\(UInt); bidsM\[this\] = 17; delete bidsM\[this\];

A new mapping of linear state may be constructed in a consensus step by
writing new Map\(TYPE\_EXPR), where TYPE\_EXPR is some type.

This returns a value which may be used to dereference particular
mappings via map\[ADDR\_EXPR\], where ADDR\_EXPR is an address. Such
dereferences return a value of type Maybe\(TYPE\_EXPR), because the
mapping may not contain a value for ADDR\_EXPR.

A mapping may be modified by writing map\[ADDR\_EXPR\] = VALUE\_EXPR to
install VALUE\_EXPR (of type TYPE\_EXPR) at ADDR\_EXPR, or by writing
delete map\[ADDR\_EXPR\] to remove the mapping entry. Such modifications
may only occur in a consensus step.

#### 5.2.7. Sets: creation and modification

const bidders = new Set\(\); bidders.insert\(Alice);
bidders.remove\(Alice); bidders.member\(Alice); // false

A Set is another container for linear state. It is simply a type alias
of Map\(Null); it is only useful for tracking Addresses. Because a Set
is internally a Map, it may only be constructed in a consensus step.

A Set may be modified by writing s.insert\(ADDRESS) to install ADDRESS
in the set, s, or s.remove\(ADDRESS) to remove the ADDRESS from the set.
Such modifications may only occur in a consensus step.

s.member\(ADDRESS) will return a Bool representing whether the address
is in the set.

## 6. Computations

This section describes the common features available in all Reach
contexts.

### 6.1. Comments

// single-line comment /\* multi-line  \* comment  \*/

Comments are text that is ignored by the compiler. Text starting with
`//` up until the end of the line forms a _single-line comment_. Text
enclosed with `/*` and `*/` forms a _multi-line comment_. It is invalid
to nest a multi-line comment within a multi-line comment.

### 6.2. Blocks

{ return 42; } { const x = 31;   return x + 11; } { if \( x < y ) {
return "Why";   } else {     return "Ecks"; } }

A _block_ is a sequence of statements surrounded by braces, i.e. `{` and
`}`.

### 6.3. Statements

This section describes the _statements_ which are allowed in any Reach
context.

Each statement affects the meaning of the subsequent statements, which
is called its _tail_. For example, if {X; Y; Z;} is a block, then X’s
tail is {Y; Z;} and Y’s tail is {Z;}.

Distinct from tails are _continuations_ which include everything after
the statement. For example, in {{X; Y;}; Z;}, X’s tail is just Y, but
its continuation is {Y;}; Z;.

Tails are statically apparent from the structure of the program source
code, while continuations are influenced by function calls.

A sequence of statements that does not end in a _terminator statement_
(a statement with no tail), such as a return statement, continue
statement, or exit statement is treated as if it ended with return
null;.

The remainder of this section enumerates each kind of statement.

#### 6.3.1. `const` and `function`

An _identifier definition_ is either a value definition or a function
definition. Each of these introduces one or more _bound identifier_s.

**—**

const DELAY = 10; const \[ Good, Bad \] = \[ 42, 43 \]; const { x, y } =
{ x: 1, y: 2 }; const \[ x, \[ y \] \] = \[ 1, \[ 2 \] \]; const \[ x, {
y } \] = \[ 1, { y: 2 } \]; const { x: \[ a, b \] } = { x: \[ 1, 2 \] };

> Valid _identifiers_ follow the same rules as JavaScript identifiers:
> they may consist of Unicode alphanumeric characters, or \_ or $, but may
> not begin with a digit.

A _value definition_ is written const LHS = RHS;.

LHS must obey the grammar:

 <_LHS_>          ` ::= `<_id_>                              
                  `  |  ``[` <_LHS-tuple-seq_> `]`           
                  `  |  ``{` <_LHS-obj-seq_> `}`             
 <_LHS-tuple-seq_>` ::= `                                    
                  `  |  ``...` <_LHS_>                       
                  `  |  `<_LHS_>                             
                  `  |  `<_LHS_> `,` <_LHS-tuple-seq_>       
 <_LHS-obj-seq_>  ` ::= `                                    
                  `  |  ``...` <_LHS_>                       
                  `  |  `<_LHS-obj-elem_>                    
                  `  |  `<_LHS-obj-elem_> `,` <_LHS-obj-seq_>
 <_LHS-obj-elem_> ` ::= `<_id_>                              
                  `  |  `<_propertyName_> `:` <_LHS_>        
 <_propertyName_> ` ::= `<_id_>                              
                  `  |  `<_string_>                          
                  `  |  `<_number_>                          
                  `  |  ``[` <_expr_> `]`                    

RHS must be compatible with the given LHS. That is, if a LHS is an
<_LHS-tuple-seq_>, then the corresponding RHS must be a tuple with the
correct number of elements. If a LHS is an <_LHS-obj-seq_>, then the
corresponding RHS must be an object with the correct fields.

Those values are available as their corresponding bound identifiers in
the statement’s tail.

**—**

function randomBool\(\) {   return \(interact.random\(\) % 2) == 0; };

A _function definition_, written function FUN\(LHS\_0, ..., LHS\_n)
BLOCK;, defines FUN as a function which abstracts its _function body_,
the block BLOCK, over the left-hand sides LHS\_0 through LHS\_n.

Function parameters may specify default arguments. The expressions used
to instantiate these parameters have access to any variables in the
scope of which the function was defined. Additionally, these expressions
may reference previous arguments of the function definition. Parameters
with default arguments must come after all other parameters.

function f\(a, b, c = a + 1, d = b + c) =>   a + b + c + d;

The last parameter of a function may be a _rest parameter_, which allows
the function to be called with an arbitrary number of arguments. A rest
parameter is specified via ...IDENT, where IDENT is bound to a Tuple
containing all the remaining arguments.

**—**

All identifiers in Reach programs must be _unbound_ at the position of
the program where they are bound, i.e., it is invalid to shadow
identifiers with new definitions. For example,

const x = 3; const x = 4;

is invalid. This restriction is independent of whether a binding is only
known to a single participant. For example,

Alice.only\(\(\) => {   const x = 3; }); Bob.only\(\(\) => {   const x =
3; });

is invalid.

The special identifier \_ is an exception to this rule. The \_ binding
is always considered to be unbound. This means means that \_ is both an
identifier that can never be read, as well as an identifier that may be
bound many times. This may be useful for ignoring unwanted values, for
example:

const \[\_, x, \_\] = \[1, 2, 3\];

#### 6.3.2. `return`

return 17; return 3 + 4; return f\(2, false); return;

A _return statement_, written return EXPR;, where EXPR is an expression
evaluates to the same value as EXPR. As a special case, return; is
interpreted the same as return null;.

A return statement returns its value to the surrounding function
application.

A return statement is a terminator statement, so it must have an empty
tail. For example,

{ return 1;   return 2; }

is invalid, because the first return’s tail is not empty.

#### 6.3.3. `if`

if \( 1 + 2 < 3 ) {   return "Yes!"; } else {   return "No, waaah!"; }

A _conditional statement_, written if \(COND) NOT\_FALSE else FALSE,
where COND is an expression and NOT\_FALSE and FALSE as statements
\(potentially block statements), selects between the NOT\_FALSE
statement and FALSE statement based on whether COND evaluates to false.

Both NOT\_FALSE and FALSE have empty tails, i.e. the tail of the
conditional statement is not propagated. For example,

if \( x < y ) {   const z = 3; } else {   const z = 4; } return z;

is erroneous, because the identifier z is not bound outside the
conditional statement.

A conditional statement may only include a consensus transfer in
NOT\_FALSE or FALSE if it is within a consensus step, because its
statements are in the same context as the conditional statement itself.

#### 6.3.4. `switch`

const mi = Maybe\(UInt).Some\(42); switch \( mi ) {  case None: return
8;  case Some: return mi + 10; } switch \( mi ) {  case None: return 8;
default: return 41; }

A _switch statement_, written switch \(VAR) { CASE ... }, where VAR is a
variable bound to a data instance and CASE is either case VARIANT: STMT
..., where VARIANT is a variant, or default: STMT ..., STMT is a
sequence of statements, selects the appropriate sequence of statements
based on which variant VAR holds. Within the body of a switch case, VAR
has the type of variant; i.e. in a Some case of a Maybe\(UInt) switch,
the variable is bound to an integer.

All cases have empty tails, i.e. the tail of the switch statement is not
propagated.

A switch statement may only include a consensus transfer in its cases if
it is within a consensus step, because its statements are in the same
context as the conditional statement itself.

It is invalid for a case to appear multiple times, or be missing, or to
be superfluous (i.e. for a variant that does not exist in the Data type
of VAR).

#### 6.3.5. Block statements

A _block statement_ is when a block occurs in a statement position, then
it establishes a local, separate scope for the definitions of
identifiers within that block. In other words, the block is evaluated
for effect, but the tail of the statements within the block are isolated
from the surrounding tail. For example,

const x = 4; return x;

evaluates to 4, but

{ const x = 4; } return x;

is erroneous, because the identifier x is not bound outside the block
statement.

#### 6.3.6. Try/Catch & Throw Statements

try {   throw 10; } catch \(v) {   transfer\(v).to\(A); }

A _try statement_, written try BLOCK catch \(VAR) BLOCK, allows a block
of code to execute with a specified handler should an exception be
thrown.

A _throw statement_, written throw EXPR, will transfer control flow to
the exception handler, binding `EXPR` to `VAR`. Any value that is able
to exist at runtime may be thrown. For example, Ints and Arrays are
valid values to throw, but a function is not.

#### 6.3.7. Expression statements

4; f\(2, true);

An expression, E, in a statement position is equivalent to the block
statement { return E; }.

### 6.4. Expressions

This section describes the expressions which are allowed in any Reach
context. There are a large variety of different _expressions_ in Reach
programs.

The remainder of this section enumerates each kind of expression.

#### 6.4.1. ’use strict’

use strict;

use strict enables unused variables checks for all subsequent
declarations within the current scope. If a variable is declared, but
never used, there will be an error emitted at compile time.

_strict mode_ will reject some code that is normally valid and limit how
dynamic Reach’s type system is. For example, normally Reach will permit
expressions like the following to be evaluated:

const foo = \(o) =>   o ? o.b : false;  void foo\({ b: true }); void
foo\(false);

Reach allows o to be either an object with a b field or false because it
partially evaluates the program at compile time. So, without use strict,
Reach will not evaluate o.b when o = false and this code will compile
successfully.

But, in strict mode, Reach will ensure that this program treats o as
having a single type and detect an error in the program as follows:

`reachc: error: Invalid field access. Expected object, got: Bool `

The correct way to write a program like this in strict mode is to use
Maybe. Like this:

const MObj = Maybe\(Object\({ b : Bool }));  const foo = \(mo) =>
mo.match\({     None: \(\(\) => false),     Some: \(\(o) => o.b)   });
void foo\(MObj.Some\({ b : true })); void foo\(MObj.None\(\)\);

#### 6.4.2. Identifier reference

X Y Z

An identifier, written ID, is an expression that evaluates to the value
of the bound identifier.

The identifier this has a special meaning inside of a local step (i.e.
the body of an only or each expression), as well as in a consensus step
(i.e. the tail of publish or pay statement and before a commit
statement). For details, see `this` and `this`.

#### 6.4.3. Function application

assert\( amount <= heap1 ) step\( moveA ) digest\( coinFlip )
interact.random\(\) declassify\( \_coinFlip )

A _function application_, written EXPR\_rator\(EXPR\_rand\_0, ...,
EXPR\_rand\_n), where EXPR\_rator and EXPR\_rand\_0 through
EXPR\_rand\_n are expressions that evaluate to one value. EXPR\_rator
must evaluate to an abstraction over n values or a primitive of arity n.
A spread expression (...expr) may appear in the list of operands to a
function application, in which case the elements of the expr are spliced
in place.

new f\(a) is equivalent to f\(a).new\(\) and is a convenient short-hand
for writing class-oriented programs.

#### 6.4.4. Types

Reach’s _type_s are represented with programs by the following
identifiers and constructors:

* Null.

* Bool, which denotes a boolean.

* UInt, which denotes an unsigned integer. UInt.max is the largest value
  that may be assigned to a UInt.

* Bytes\(length), which denotes a string of bytes of length at most
  length.

* Digest, which denotes a digest.

* Address, which denotes an account address.

* Token, which denotes a non-network token.

* Fun\(\[Domain\_0, ..., Domain\_N\], Range), which denotes a _function
  type_. The domain of a function is negative position. The range of a
  function is positive position.

* Tuple\(Field\_0, ..., FieldN), which denotes a tuple. \(Refer to
  Tuples for constructing tuples.)

* Object\({key\_0: Type\_0, ..., key\_N: Type\_N}), which denotes an
  object. \(Refer to Objects for constructing objects.)

* Struct\(\[\[key\_0, Type\_0\], ..., \[key\_N, Type\_N\]\]), which
  denotes a struct. \(Refer to Structs for constructing structs.)

* Array\(Type\_0, size), which denotes a statically-sized array. Type\_0
  must be a type that can exist at runtime (i.e., not a function type.)
  \(Refer to `array` for constructing arrays.)

* Data\({variant\_0: Type\_0, ..., variant\_N: Type\_N}), which denotes
  a [tagged union](https://en.wikipedia.org/wiki/Tagged_union) (or ​_sum
  type_​). \(Refer to Data for constructing data instances.)

* Refine\(Type\_0, Predicate, ?Message), where Predicate is a unary
  function returning a boolean, which denotes a [refinement
  type](https://en.wikipedia.org/wiki/Refinement_type), that is
  instances of Type\_0 that satisfy Predicate. When a refinement type
  appears in a _negative position_ (such as in a is or in the domain of
  a Fun of a participant interact interface), it introduces an assert;
  while when it is in a _positive position_, it introduces an assume.
  Message is an optional string to display if the predicate fails
  verification.

  For example, if f had type Fun\(\[Refine\(UInt, \(x => x < 5))\],
  Refine\(UInt, \(x => x > 10)))

  then const z = f\(y) is equivalent to

  assert\(y < 5); const z = f\(y); assume\(z > 10);

* Refine\(Type\_0, PreCondition, PostCondition, ?Messages), where
  Type\_0 is a function type, PreCondition is a unary function that
  accepts a tuple of the domain and returns a boolean, and PostCondition
  is a binary function that accepts a tuple of the domain and the range
  and returns a boolean, denotes a function type with a
  [precondition](https://en.wikipedia.org/wiki/Precondition) and
  [postcondition](https://en.wikipedia.org/wiki/Postcondition).
  Preconditions are enforced with assert and postconditions are enforced
  with assume. Messages is an optional two-tuple of Bytes. The first
  message will be displayed when the precondition fails verification and
  the second when the postcondition fails verification.

  For example, Refine\(Fun\(\[UInt, UInt\], UInt), \(\[x, y\] => x < y),
  \(\(\[x, y\], z) => x + y < z)) is a function that requires its second
  argument to be larger than its first and its result to be larger than
  its input.

Object and Data are commonly used to implemented [algebraic data
types](https://en.wikipedia.org/wiki/Algebraic_data_type) in Reach.

typeOf\(x) // type isType\(t) // Bool is\(x, t) // t

The typeOf primitive function is the same as typeof: it returns the type
of its argument.

The isType function returns true if its argument is a type. Any
expression satisfying isType is compiled away and does not exist at
runtime.

The is function returns its first argument if it satisfies the type
specified by the second argument. If it is not, then the program is
invalid. For example, is\(5, UInt) returns 5, while is\(5, Bool) is an
invalid program. The value returned by is may not be identical to the
input, because in some cases, such as for functions, it will record the
applied to type and enforce it on future invocations. These applications
are considered negative positions for Refine.

#### 6.4.5. Literal values

10 0xdeadbeef 007 -10 34.5432 true false null "reality bytes" it just
does

A _literal value_, written VALUE, is an expression that evaluates to the
given value.

The _null literal_ may be written as null.

_Numeric literal_s may be written in decimal, hexadecimal, or octal.
Numeric literals must obey the _bit width_ of UInt if they are used as
UInt values at runtime, but if they only appear at compile-time, then
they may be any positive number. Reach provides abstractions for working
with Ints and signed FixedPoint numbers. Ints may be defined by applying
the unary + and - operators to values of type UInt. Reach provides
syntactic sugar for defining signed FixedPoint numbers, in base 10, with
decimal syntax.

_Boolean literal_s may be written as true or false.

_String literal_s (aka byte strings) may be written between double or
single quotes \(with no distinction between the different styles\) and
use the same escaping rules as JavaScript.

#### 6.4.6. Operator expression

An _operator_ is a special identifier, which is either a unary operator,
or a binary operator.

**—**

! a  // not - a  // minus + a  // plus typeof a void a

A _unary expression_, written UNAOP EXPR\_rhs, where EXPR\_rhs is an
expression and UNAOP is one of the _unary operator_s: `! - + typeof
void`. All the unary operators, besides typeof, have a corresponding
named version in the standard library.

It is invalid to use unary operations on the wrong types of values.

When applied to values of type UInt, unary - and + operators will cast
their arguments to type Int. The unary - and + operations are defined
for values of type: Int, and FixedPoint.

void a evaluates to null for all arguments.

**—**

a && b a || b a + b a - b a \* b a / b a % b a | b a & b a ^ b a << b a
>> b a == b a != b a === b a !== b a > b a >= b a <= b a < b

> Bitwise operations are not supported by all consensus networks and
> greatly decrease the efficiency of verification.

A _binary expression_, written EXPR\_lhs BINOP EXPR\_rhs, where
EXPR\_lhs and EXPR\_rhs are expressions and BINOP is one of the _binary
operator_s: `&& || + - * / % | & ^ << >> == != === !== > >= <= <`. The
operators == (and ===) and != (and !==) operate on all atomic values.
Numeric operations, like + and >, only operate on numbers. Since all
numbers in Reach are integers, operations like / truncate their result.
Boolean operations, like &&, only operate on booleans. It is invalid to
use binary operations on the wrong types of values.

and\(a, b)     // && or\(a, b)      // || add\(a, b)     // + sub\(a, b)
// - mul\(a, b)     // \* div\(a, b)     // / mod\(a, b)     // % lt\(a,
b)      // < le\(a, b)      // <= ge\(a, b)      // >= gt\(a, b)      //
> lsh\(a, b)     // << rsh\(a, b)     // >> band\(a, b)    // & bior\(a,
b)    // | bxor\(a, b)    // ^ polyEq\(a, b)  // ==, === polyNeq\(a, b)
// !=, !==

All binary expression operators have a corresponding named function in
the standard library. While && and || may not evaluate their second
argument, their corresponding named functions and and or, always do.

polyEq\(a, b)    // eq on all types boolEq\(a, b)    // eq on Bool
typeEq\(a, b)    // eq on types intEq\(a, b)     // eq on UInt
digestEq\(a, b)  // eq on Digest addressEq\(a, b) // eq on Addresses
fxeq\(a, b)      // eq on FixedPoint ieq\(a, b)       // eq on Int

== is a function which operates on all types. Both arguments must be of
the same type. Specialized functions exist for equality checking on each
supported type.

**—**

If verifyArithmetic is true, then arithmetic operations automatically
make a static assertion that their arguments would not overflow the bit
width of the enable consensus networks. If it is false, then the
connector will ensure this dynamically.

#### 6.4.7. xor

xor\(false, false); // false xor\(false, true);  // true xor\(true,
false);  // true xor\(true, true);   // false

xor\(Bool, Bool) returns true only when the inputs differ in value.

#### 6.4.8. Parenthesized expression

\(a + b) - c

An expression may be parenthesized, as in \(EXPR).

#### 6.4.9. Tuples

\[ \] \[ 1, 2 + 3, 4 \* 5 \]

A _tuple_ literal, written \[ EXPR\_0, ..., EXPR\_n \], is an expression
which evaluates to a tuple of n values, where EXPR\_0 through EXPR\_n
are expressions.

...expr may appear inside tuple expressions, in which case the spreaded
expression must evaluate to a tuple or array, which is spliced in place.

#### 6.4.10. `array`

const x = array\(UInt, \[1, 2, 3\]);

Converts a tuple of homogeneous values of the specific type into an
_array_.

#### 6.4.11. Element reference

arr\[3\]

A _reference_, written REF\_EXPR\[IDX\_EXPR\], where REF\_EXPR is an
expression that evaluates to an array, a tuple, or a struct and
IDX\_EXPR is an expression that evaluates to a natural number which is
less than the size of the array, selects the element at the given index
of the array. Indices start at zero.

If REF\_EXPR is a tuple, then IDX\_EXPR must be a compile-time constant,
because tuples do not support dynamic access, because each element may
be a different type.

If REF\_EXPR is a mapping and IDX\_EXPR evaluates to an address, then
this reference evaluates to a value of type Maybe\(TYPE), where TYPE is
the type of the mapping.

#### 6.4.12. Array & tuple length: `Tuple.length`, `Array.length`, and `.length`

Tuple.length\(tup); tup.length; Array.length\(arr); arr.length;

Tuple.length Returns the length of the given tuple.

Array.length Returns the length of the given array.

Both may be abbreviated as expr.length where expr evaluates to a tuple
or an array.

#### 6.4.13. Array & tuple update: `Tuple.set`, `Array.set`, and `.set`

Tuple.set\(tup, idx, val); tup.set\(idx, val); Array.set\(arr, idx,
val); arr.set\(idx, val);

Tuple.set Returns a new tuple identical to tup, except that index idx is
replaced with val. The idx must be a compile-time constant, because
tuples do not support dynamic access, because each element may be a
different type.

Array.set Returns a new array identical to arr, except that index idx is
replaced with val.

Both may be abbreviated as expr.set\(idx, val) where expr evaluates to a
tuple or an array.

#### 6.4.14. Foldable operations

The following methods are available on any Foldable containers, such as:
Arrays and Maps.

`Foldable.forEach` && `.forEach`

c.forEach\(f) Foldable.forEach\(c, f) Array.forEach\(c, f)
Map.forEach\(c, f)

Foldable.forEach\(c, f) iterates the function f over the elements of a
container c, discarding the result. This may be abbreviated as
c.forEach\(f).

`Foldable.all` && `.all`

Foldable.all\(c, f) Array.all\(c, f) Map.all\(c, f) c.all\(f)

Foldable.all\(c, f) determines whether the predicate, `f`, is satisfied
by every element of the container, `c`.

`Foldable.any` && `.any`

Foldable.any\(c, f) Array.any\(c, f) Map.any\(c, f) c.any\(f)

Foldable.any\(c, f) determines whether the predicate, `f`, is satisfied
by at least one element of the container, `c`.

`Foldable.or` && `.or`

Foldable.or\(c) Array.or\(c) Map.or\(c) c.or\(\)

Foldable.or\(c) returns the disjunction of a container of Bools.

`Foldable.and` && `.and`

Foldable.and\(c) Array.and\(c) Map.and\(c) c.and\(\)

Foldable.and\(c) returns the conjunction of a container of Bools.

`Foldable.includes` && `.includes`

Foldable.includes\(c, x) Array.includes\(c, x) Map.includes\(c, x)
c.includes\(x)

Foldable.includes\(c, x) determines whether the container includes the
element, `x`.

`Foldable.count` && `.count`

Foldable.count\(c, f) Array.count\(c, f) Map.count\(c, f) c.count\(f)

Foldable.count\(c, f) returns the number of elements in `c` that satisfy
the predicate, `f`.

`Foldable.size` && `.size`

Foldable.size\(c) Array.size\(c) Map.size\(c) c.size\(\)

Foldable.size\(c) returns the number of elements in `c`.

`Foldable.min` && `.min`

Foldable.min\(c) Array.min\(c) Map.min\(c) c.min\(\)

Foldable.min\(arr) returns the lowest number in a container of `UInt`s.

`Foldable.max` && `.max`

Foldable.max\(c) Array.max\(c) Map.max\(c) c.max\(\)

Foldable.max\(c) returns the largest number in a container of `UInt`s.

`Foldable.sum` && `.sum`

Foldable.sum\(c) Array.sum\(c) Map.sum\(c) c.sum\(\)

Foldable.sum\(c) returns the sum of a container of `UInt`s.

`Foldable.product` && `.product`

Foldable.product\(c) Array.product\(c) Map.product\(c) c.product\(\)

Foldable.product\(c) returns the product of a container of `UInt`s.

`Foldable.average` && `.average`

Foldable.average\(c) Array.average\(c) Map.average\(c) c.average\(\)

Foldable.average\(c) returns the mean of a container of `UInt`s.

#### 6.4.15. Array group operations

Array is a Foldable container. Along with the methods of Foldable, the
following methods may be used with Arrays.

`Array.iota`

Array.iota\(5)

Array.iota\(len) returns an array of length len, where each element is
the same as its index. For example, Array.iota\(4) returns \[0, 1, 2,
3\]. The given len must evaluate to an integer at compile-time.

`Array.replicate` && `.replicate`

Array.replicate\(5, "five") Array\_replicate\(5, "five")

Array.replicate\(len, val) returns an array of length len, where each
element is val. For example, Array.replicate\(4, "four") returns
\["four", "four", "four", "four"\]. The given len must evaluate to an
integer at compile-time.

`Array.concat` && `.concat`

Array.concat\(x, y) x.concat\(y)

Array.concat\(x, y) concatenates the two arrays x and y. This may be
abbreviated as x.concat\(y).

`Array.empty`

Array\_empty Array.empty

Array.empty is an array with no elements. It is the identity element of
Array.concat. It may also be written Array\_empty.

`Array.zip` && `.zip`

Array.zip\(x, y) x.zip\(y)

Array.zip\(x, y) returns a new array the same size as x and y (which
must be the same size) whose elements are tuples of the elements of x
and y. This may be abbreviated as x.zip\(y).

`Array.map` && `.map`

Array.map\(arr, f) arr.map\(f)

Array.map\(arr, f) returns a new array, arr\_mapped, the same size as
arr, where arr\_mapped\[i\] = f\(arr\[i\]) for all i. For example,
Array.iota\(4).map\(x => x+1) returns \[1, 2, 3, 4\]. This may be
abbreviated as arr.map\(f).

This function is generalized to an arbitrary number of arrays of the
same size, which are provided before the f argument. For example,
Array.iota\(4).map\(Array.iota\(4), add) returns \[0, 2, 4, 6\].

`Array.reduce` && `.reduce`

Array.reduce\(arr, z, f) arr.reduce\(z, f)

Array.reduce\(arr, z, f) returns the [left
fold](https://en.wikipedia.org/wiki/Fold_&higher-order_function)) of the
function f over the given array with the initial value z. For example,
Array.iota\(4).reduce\(0, add) returns \(\(0 + 1) + 2) + 3 = 6. This may
be abbreviated as arr.reduce\(z, f).

This function is generalized to an arbitrary number of arrays of the
same size, which are provided before the z argument. For example,
Array.iota\(4).reduce\(Array.iota\(4), 0, \(x, y, z) => \(z + x + y))
returns \(\(\(\(0 + 0 + 0) + 1 + 1) + 2 + 2) + 3 + 3).

`Array.indexOf` && `.indexOf`

Array.indexOf\(arr, x) arr.indexOf\(x)

Array.indexOf\(arr, x) returns the index of the first element in the
given array that is equal to `x`. The return value is of type
Maybe\(UInt). If the value is not present in the array, None is
returned.

`Array.findIndex` && `.findIndex`

Array.findIndex\(arr, f) arr.findIndex\(f)

Array.findIndex\(arr, f) returns the index of the first element in the
given array that satisfies the predicate `f`. The return value is of
type Maybe\(UInt). If no value in the array satisfies the predicate,
None is returned.

#### 6.4.16. Mapping group operations

Map is a Foldable container. Mappings may be aggregated with the
following operations and those of Foldable within the invariant of a
while loop.

`Map.reduce` && `.reduce`

Map.reduce\(map, z, f) map.reduce\(z, f)

Map.reduce\(map, z, f) returns the [left
fold](https://en.wikipedia.org/wiki/Fold_&higher-order_function)) of the
function f over the given mapping with the initial value z. For example,
m.reduce\(0, add) sums the elements of the mapping. This may be
abbreviated as map.reduce\(z, f).

The function f must satisfy the property, for all z, a, b, f\(f\(z, b),
a) == f\(f\(z, a), b), because the order of evaluation is unpredictable.

#### 6.4.17. Objects

{ } { x: 3, "yo-yo": 4 } { \[1 < 2 ? "one" : "two"\]: 5 }

An _object_, typically written { KEY\_0: EXPR\_0, ..., KEY\_n: EXPR\_n
}, where KEY\_0 through KEY\_n are identifiers or string literals and
EXPR\_0 through EXPR\_n are expressions, is an expression which
evaluates to an object with fields KEY\_0 through KEY\_n.

Additional object literal syntax exists for convenience, such as:

{ ...obj, z: 5 }

An _object splice_, where all fields from obj are copied into the
object; these fields may be accompanied by additional fields specified
afterwards.

{ x, z: 5 }

Shorthand for { x: x, z: 5}, where x is any bound identifier.

#### 6.4.18. Structs

const Posn = Struct\(\[\["x", UInt\], \["y", UInt\]\]); const p1 =
Posn.fromObject\({x: 1, y: 2}); const p2 = Posn.fromTuple\(\[1, 2\]);

A _struct_ is a combination of a tuple and an object. It has named
elements, like an object, but is ordered like a tuple, so its elements
may be accessed by either name or position. Structs exist for
interfacing with non-Reach remote objects, where both parties must agree
to the runtime representation of the values.

A struct instance may be constructed by calling the fromTuple method of
a struct type instance (like Posn) with a tuple of the appropriate
length.

A struct instance may be constructed by calling the fromObject method of
a struct type instance (like Posn) with an object with the appropriate
fields.

Structs may be converted into a corresponding tuple or object via the
toTuple and toObject methods on the Struct value (as well as struct type
instances, like Posn in the example above):

assert\(Posn.toTuple\(p1)\[0\] == 1); assert\(Struct.toObject\(p2).y ==
2);

#### 6.4.19. Field reference

obj.x

An _object reference_, written OBJ.FIELD, where OBJ is an expression
that evaluates to an object or a struct, and FIELD is a valid
identifier, accesses the `FIELD` _field_ of object OBJ.

#### 6.4.20. `Object.set`

Object.set\(obj, fld, val); Object\_set\(obj, fld, val); { ...obj,
\[fld\]: val };

Returns a new object identical to obj, except that field fld is replaced
with val.

#### 6.4.21. `Object.setIfUnset`

Object.setIfUnset\(obj, fld, val); Object\_setIfUnset\(obj, fld, val);

Returns a new object identical to obj, except that field fld is val if
fld is not already present in obj.

#### 6.4.22. `Object.has`

Object.has\(obj, fld);

Returns a boolean indicating whether the object has the field fld. This
is statically known.

#### 6.4.23. Data

const Taste = Data\({Salty: Null,                     Spicy: Null,
Sweet: Null,                     Umami: Null}); const burger =
Taste.Umami\(\);  const Shape = Data\({ Circle: Object\({r: UInt}),
Square: Object\({s: UInt}),                      Rect: Object\({w: UInt,
h: UInt}) }); const nice = Shape.Circle\({r: 5});

A _data instance_ is written DATA.VARIANT\(VALUE), where DATA is Data
type, VARIANT is the name of one of DATA’s variants, and VALUE is a
value matching the type of the variant. As a special case, when the type
of a variant is Null, the VALUE may be omitted, as shown in the
definition of burger in the same above.

Data instances are consumed by switch statements.

#### 6.4.24. `Maybe`

const MayInt = Maybe\(UInt); const bidA = MayInt.Some\(42); const bidB =
MayInt.None\(null);  const getBid = \(m) => fromMaybe\(m, \(\(\) => 0),
\(\(x) => x)); const bidSum = getBid\(bidA) + getBid\(bidB);
assert\(bidSum == 42);

[Option types](https://en.wikipedia.org/wiki/Option_type) are
represented in Reach through the built-in Data type, Maybe, which has
two variants: Some and None.

Maybe is defined by export const Maybe = \(A) => Data\({None: Null,
Some: A});

This means it is a function that returns a Data type specialized to a
particular type in the Some variant.

Maybe instances can be conveniently consumed by fromMaybe\(mValue,
onNone, onSome), where onNone is a function of no arguments which is
called when mValue is None, onSome is a function of on argument which is
called with the value when mValue is Some, and mValue is a data instance
of Maybe.

const m = Maybe\(UInt).Some\(5); isNone\(m); // false isSome\(m); //
true

isNone is a convenience method that determines whether the variant is
`isNone`.

isSome is a convenience method that determines whether the variant is
`isSome`.

fromSome\(Maybe\(UInt).Some\(1), 0); // 1
fromSome\(Maybe\(UInt).None\(\), 0);  // 0

fromSome receives a Maybe value and a default value as arguments and
will return the value inside of the Some variant or the default value
otherwise.

const add1 = \(x) => x + 1; maybe\(Maybe\(UInt).Some\(1), 0, add1); // 2
maybe\(Maybe\(UInt).None\(\), 0, add1);  // 0

maybe\(m, defaultVal, f) receives a Maybe value, a default value, and a
unary function as arguments. The function will either return the
application of the function, f, to the Some value or return the default
value provided.

#### 6.4.25. `Either`

Either is defined by export const Either = \(A, B) => Data\({Left: A,
Right: B});

Either can be used to represent values with two possible types.

Similar to `Maybe`, `Either` may be used to represent values that are
correct or erroneous. A successful result is stored, by convention, in
`Right`. Unlike `None`, `Left` may carry additional information about
the error.

either\(e, onLeft, onRight)

either\(e, onLeft, onRight) For an `Either` value, `e`, `either` will
either apply the function `onLeft` or `onRight` to the appropriate
variant value.

const e = Either\(UInt, Bool); const l = e.Left\(1); const r =
e.Right\(true); isLeft\(l);  // true isRight\(l); // false const x =
fromLeft\(l, 0);      // x = 1 const y = fromRight\(l, false); // y =
false

isLeft is a convenience method that determines whether the variant is
`Left`.

isRight is a convenience method that determines whether the variant is
`Right`.

fromLeft\(e, default) is a convenience method that returns the value in
`Left`, or `default` if the variant is `Right`.

fromRight\(e, default) is a convenience method that returns the value in
`Right`, or `default` if the variant is `Left`.

#### 6.4.26. `match`

const Value = Data\({    EBool: Bool,    EInt: UInt,    ENull: Null,
});  const v1 = Value.EBool\(true);  const v2 = Value.EInt\(200);  const
isTruthy = \(v) =>    v.match\({      EBool: \(b) => { return b },
EInt : \(i) => { return i != 0 },      ENull: \(\)  => { return false }
});   assert\(isTruthy\(v1));  assert\(isTruthy\(v2));

A _match expression_, written VAR.match\({ CASE ... }), where `VAR` is a
variable bound to a data instance and `CASE` is `VARIANT: FUNCTION`,
where `VARIANT` is a variant or default, and `FUNCTION` is a function
that takes the same arguments as the variant constructor. If the variant
has a type of Null, then the function is allowed to take no arguments.
default functions must always take an argument, even if all defaulted
variants have type Null.

match is similar to a switch statement, but since it is an expression,
it can be conveniently used in places like the right hand side of an
assignment statement.

Similar to a switch statement, the cases are expected to be exhaustive
and nonredundant, all cases have empty tails, and it may only include a
consensus transfer in its cases if it is within a consensus step.

#### 6.4.27. Conditional expression

choosesFirst ? \[ heap1 - amount, heap2 \] : \[ heap1, heap2 - amount \]

A _conditional expression_, written COND\_E ? NOT\_FALSE\_E : FALSE\_E,
where COND\_E, NOT\_FALSE\_E, and FALSE\_E are expressions, selects
between the values which NOT\_FALSE\_E and FALSE\_E evaluate to based on
whether COND\_E evaluates to false.

ite\(choosesFirst, \[heap1 - amount, heap2\], \[heap1, heap2 - amount\])

Conditional expressions may also be written with the ite function,
however, note that this function always evaluates both of its branches,
while the regular conditional expression only evaluates one branch.

#### 6.4.28. Arrow expression

\(\(\) => 4) \(\(x) => x + 1) \(\(x) => { const y = x + 1;
return y + 1; }) \(\(x, y) => { assert\(x + y == 3); })(1, 2); \(\(x, y)
=> { assert\(x + y == 3); })(...\[1, 2\]); \(\(x, y = 2) => { assert\(x
+ y == 3); })(1); \(\(x, y = 2) => { assert\(x + y == 2); })(1, 1);
\(\(\[x, y\]) => { assert\(x + y == 3); })(\[1, 2\]); \(\({x, y}) => {
assert\(x + y == 3); })({x: 1, y: 2}); \(\(\[x, \[y\]\]) => { assert\(x
+ y == 3); })(\[1,\[2\]\]); \(\(\[x, {y}\]) => { assert\(x + y == 3);
})(\[1,{ y: 2 }\]); \(\(...xs) => Foldable.sum\(xs))(1, 2, 3)

An _arrow expression_, written \(LHS\_0, ..., LHS\_n) => EXPR, where
LHS\_0 through LHS\_n are left-hand sides and EXPR is an expression,
evaluates to an function which is an abstraction of EXPR over n values
compatible with the respective left-hand side. Like function
definitions, arrow expressions may use default argument notation and
rest parameters.

#### 6.4.29. `makeEnum`

const \[ isHand, ROCK, PAPER, SCISSORS \] = makeEnum\(3);

An _enumeration_ (or _enum_, for short), can be created by calling the
makeEnum function, as in makeEnum\(N), where N is the number of distinct
values in the enum. This produces a tuple of N+1 values, where the first
value is a Fun\(\[UInt\], Bool) which tells you if its argument is one
of the enum’s values, and the next N values are distinct UInts.

#### 6.4.30. `assert`

assert\( claim, \[msg\] )

A static assertion which is only valid if claim always evaluates to
true.

> The Reach compiler will produce a counter-example (i.e. an assignment of
> the identifiers in the program to falsify the claim) when an invalid
> claim is provided. It is possible to write a claim that actually always
> evaluates to true, but for which our current approach cannot prove
> always evaluates to true; if this is the case, Reach will fail to
> compile the program, reporting that its analysis is incomplete. Reach
> will never produce an erroneous counter-example.

It accepts an optional bytes argument, which is included in any reported
violation.

> See the guide section on verification to better understand how and what
> to verify in your program.

#### 6.4.31. `forall`

forall\( Type ) forall\( Type, \(var) => BLOCK )

The single argument version returns an abstract value of the given type.
It may only be referenced inside of assertions; any other reference is
invalid.

The two argument version is an abbreviation of calling the second
argument with the result of forall\(Type). This is convenient for
writing general claims about expressions, such as

forall\(UInt, \(x) => assert\(x == x));

#### 6.4.32. `possible`

possible\( claim, \[msg\] )

A possibility assertion which is only valid if it is possible for claim
to evaluate to true with honest frontends and participants. It accepts
an optional bytes argument, which is included in any reported violation.

#### 6.4.33. `digest`

digest\( arg\_0, ..., arg\_n )

The digest primitive performs a [cryptographic
hash](https://en.wikipedia.org/wiki/Cryptographic_hash_function) of the
binary encoding of the given arguments. This returns a Digest value. The
exact algorithm used depends on the connector.

#### 6.4.34. `balance`

balance\(\); balance\(gil);

The _balance_ primitive returns the balance of the contract account for
the DApp. It takes an optional non-network token value, in which case it
returns the balance of the given token.

#### 6.4.35. `lastConsensusTime`

lastConsensusTime\(\)

The _lastConsensusTime_ primitive returns the time of the last
publication of the DApp. This may not be available if there was no such
previous publication, such as at the beginning of an application where
deployMode is firstMsg.

> Why is there no `thisConsensusTime`? Some networks do not support
> observing the time of a consensus operation until after it has
> finalized. This aides scalability, because it increases the number of
> times when an operation could be finalized.

#### 6.4.36. `makeDeadline`

const \[ timeRemaining, keepGoing \] = makeDeadline\(10);

makeDeadline\(deadline) takes an UInt as an argument and returns a pair
of functions that can be used for dealing with absolute deadlines. It
internally determines the end time based off of the deadline and the
last consensus time—at the time of calling makeDeadline. `timeRemaining`
will calculate the difference between the end time and the current last
consensus time. `keepGoing` determines whether the current last
consensus time is less than the end time. It is typical to use the two
fields for the `while` and `timeout` field of a parallelReduce
expression. For example:

const \[ timeRemaining, keepGoing \] = makeDeadline\(10); const \_ =
parallelReduce\(...\)   .invariant\(...\)   .while\( keepGoing\(\) )
.case\(...\)   .timeout\( timeRemaining\(\), \(\) => { ... })

This pattern is so common that it can be abbreviated as .timeRemaining.

#### 6.4.37. `implies`

implies\( x, y )

Returns true if x is false or y is true.

#### 6.4.38. `ensure`

ensure\( pred, x )

Makes a static assertion that pred\(x) is true and returns x.

#### 6.4.39. `hasRandom`

hasRandom

A participant interact interface which specifies `random` as a function
that takes no arguments and returns an unsigned integer of bit width
bits.

#### 6.4.40. `compose`

compose\(f, g)

Creates a new function that applies it’s argument to `g`, then pipes the
result to the function `f`. The argument type of `f` must be the return
type of `g`.

#### 6.4.41. `sqrt`

sqrt\(81, 10)

Calculates an approximate square root of the first argument. This method
utilizes the [Babylonian
Method](https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
for computing the square root. The second argument must be an UInt whose
value is known at compile time, which represents the number of
iterations the algorithm should perform.

For reference, when performing 5 iterations, the algorithm can reliably
calculate the square root up to `32` squared, or `1,024`. When
performing 10 iterations, the algorithm can reliably calculate the
square root up to `580` squared, or `336,400`.

#### 6.4.42. `pow`

pow \(2, 40, 10) // => 1,099,511,627,776

pow\(base, power, precision) Calculates the approximate value of raising
base to power. The third argument must be an UInt whose value is known
at compile time, which represents the number of iterations the algorithm
should perform. For reference, `6` iterations provides enough accuracy
to calculate up to `2^64 - 1`, so the largest power it can compute is
`63`.

#### 6.4.43. Signed Integers

The standard library provides abstractions for dealing with signed
integers. The following definitions are used to represent Ints:

> `Int` is represented as an object, as opposed to a scalar value, because
> some platforms that Reach targets do not provide native support for
> signed integers.

const Int = { sign: bool, i: UInt }; const Pos = true; const Neg =
false;

int\(Bool, UInt) is shorthand for defining an Int record. You may also
use the + and - unary operators to declare integers instead of UInts.

int\(Pos, 4); // represents 4 int\(Neg, 4); // represents -4 -4;
// represents -4 +4;          // represents 4 : Int  4;          //
represents 4 : UInt

iadd\(x, y) adds the Int `x` and the Int `y`.

isub\(x, y) subtracts the Int `y` from the Int `x`.

imul\(x, y) multiplies the Int `x` and the Int `y`.

idiv\(x, y) divides the Int `x` by the Int `y`.

imod\(x, y) finds the remainder of dividing the Int `x` by the Int `y`.

ilt\(x, y) determines whether `x` is less than `y`.

ile\(x, y) determines whether `x` is less than or equal to `y`.

igt\(x, y) determines whether `x` is greather than `y`.

ige\(x, y) determines whether `x` is greater than or equal to `y`.

ieq\(x, y) determines whether `x` is equal to `y`.

ine\(x, y) determines whether `x` is not equal to `y`.

imax\(x, y) returns the larger of two Ints.

abs\(i) returns the absolute value of an Int. The return value is of
type UInt.

#### 6.4.44. Fixed-Point Numbers

FixedPoint is defined by

export const FixedPoint = Object\({ sign: bool, i: Object\({ scale:
UInt, i: UInt }) });

FixedPoint can be used to represent numbers with a fixed number of
digits after the decimal point. They are handy for representing
fractional values, especially in base 10. The value of a fixed point
number is determined by dividing the underlying integer value, `i`, by
its scale factor, `scale`. For example, we could represent the value
1.234 with { sign: Pos, i: { scale: 1000, i : 1234 } } or fx\(1000)(Pos,
1234). Alternatively, Reach provides syntactic sugar for defining
FixedPoint numbers. One can simply write 1.234, which will assume the
value is in base 10. A scale factor of `1000` correlates to 3 decimal
places of precision. Similarly, a scale factor of `100` would have 2
decimal places of precision.

const scale = 10; const i = 56; fx\(scale)(Neg, i); // represents - 5.6

fx\(scale)(i) will return a function that can be used to instantiate
fixed point numbers with a particular scale factor.

const i = 4; fxint\(-i); // represents - 4.0

fxint\(Int) will cast the Int arg as a FixedPoint number with a `scale`
of 1.

const x = fx\(1000)(Pos, 1234); // x = 1.234 fxrescale\(x, 100);    //
=> 1.23

fxrescale\(x, scale) will convert a fixed point number from using one
scale to another. This operation can result in loss of precision, as
demonstrated in the above example.

const x = fx\(1000)(Pos, 824345); // x = 824.345 const y = 45.67;
fxunify\(x, y);    // => \[ 1000, 824.345, 45.670 \]

fxunify\(x, y) will convert the fixed point numbers to use the same
scale. The larger scale of the two arguments will be chosen. The
function will return a `3-tuple` consisting of the common scale and the
newly scaled values.

fxadd\(x, y) adds two fixed point numbers.

fxsub\(x, y) subtracts two fixed point numbers.

fxmul\(x, y) multiplies two fixed point numbers.

fxdiv\(34.56, 1.234, 10)     // => 28 fxdiv\(34.56, 1.234, 100000) // =>
28.0064

fxdiv\(x, y, scale\_factor) divides two fixed point numbers. The
numerator, `x`, will be multiplied by the scale factor to provide a more
precise answer. For example,

fxmod\(x, y) finds the remainder of dividing `x` by `y`.

fxfloor\(x) returns the greatest integer not greater than `x`.

fxsqrt\(x, k) approximates the sqrt of the fixed number, `x`, using `k`
iterations of the sqrt algorithm.

const base  = 2.0;const power = 0.33;fxpow\(base, power, 10, 1000);
// 1.260fxpow\(base, power, 10, 10000);   // 1.2599fxpow\(base, power,
10, 1000000); // 1.259921

fxpow\(base, power, precision, scalePrecision) approximates the power of
the fixed number, `base`, raised to the fixed point number, `power`. The
third argument must be an UInt whose value is known at compile time,
which represents the number of iterations the algorithm should perform.
The `scalePrecision` argument must be a `UInt` and represents the scale
of the return value. Choosing a larger `scalePrecision` allows for more
precision when approximating the power, as demonstrated in the example
below:

fxpowi\(base, power, precision) approximates the power of the fixed
number, `base`, raised to the Int, `power`. The third argument must be
an UInt whose value is known at compile time, which represents the
number of iterations the algorithm should perform. For reference, `6`
iterations provides enough accuracy to calculate up to `2^64 - 1`, so
the largest power it can compute is `63`.

fxpowui\(5.8, 3, 10); // 195.112

fxpowui\(base, power, precision) approximates the power of the fixed
number, `base`, raised to the UInt, `power`. The third argument must be
an UInt whose value is known at compile time.

fxcmp\(op, x, y) applies the comparison operator to the two fixed point
numbers after unifying their scales.

There are convenience methods defined for comparing fixed point numbers:

fxlt\(x, y) tests whether `x` is less than `y`.

fxle\(x, y) tests whether `x` is less than or equal to `y`.

fxgt\(x, y) tests whether `x` is greater than `y`.

fxge\(x, y) tests whether `x` is greater than or equal to `y`.

fxeq\(x, y) tests whether `x` is equal to `y`.

fxne\(x, y) tests whether `x` is not equal to `y`.

#### 6.4.45. Anybody

Anybody.publish\(\); // race(...Participants).publish()

Reach provides a shorthand, Anybody, which serves as a race between all
participants. This shorthand can be useful for situations where it does
not matter who publishes, such as in a timeout.

Anybody is strictly an abbreviation of a race involving all of the named
participants of the application. In an application with a participant
class, this means any principal at all, because there is no restriction
on which principals (i.e. addresses) may serve as a member of that
class. In an application without any participant classes, Anybody
instead would mean only the actual previously-bound participants.

#### 6.4.46. Intervals

An Interval is defined by

export const Interval = Tuple\(IntervalType, Int, Int, IntervalType);

where IntervalType is defined by

export const \[ isIntervalType, Closed, Open \] = mkEnum\(2); export
const IntervalType = Refine\(UInt, isIntervalType);

Constructors

An interval may be constructed with its tuple notation or by function:

// Representing \[-10, +10) const i1 = \[Closed, -10, +10, Open\]; const
i2 = interval\(Closed, -10, +10, Open); const i3 = intervalCO\(-10,
+10);

For convenience, Reach provides a number of functions for constructing
intervals:

interval\(IntervalType, Int, Int, IntervalType) constructs an interval
where the first and second argument represent the left endpoint and
whether it’s open or closed; the third and fourth argument represent the
right endpoint and whether it’s open or closed.

intervalCC\(l, r) constructs a closed interval from two endpoints of
type Int.

intervalCO\(l, r) constructs a half-open interval from two endpoints of
type Int where the left endpoint is closed and the right endpoint is
open.

intervalOC\(l, r) constructs a half-open interval from two endpoints of
type Int where the left endpoint is open and the right endpoint is
closed.

intervalOO\(l, r) constructs an open interval from two endpoints of type
Int.

Accessors

leftEndpoint\(i) will return the Int that represents the left endpoint
of an interval.

rightEndpoint\(i) will return the Int that represents the right endpoint
of an interval.

Relational Operations

Intervals may be compared with the following functions:

intervalEq\(l, r) tests whether the intervals are equal.

intervalNe\(l, r) tests whether the intervals are not equal.

intervalLt\(l, r) tests whether the left interval is less than the right
interval.

intervalLte\(l, r) tests whether the left interval is less than or equal
to the right interval.

intervalGt\(l, r) tests whether the left interval is greater than the
right interval.

intervalGte\(l, r) tests whether the left interval is greater than or
equal to the right interval.

Arithmetic Operations

intervalAdd\(l, r) adds the two intervals.

intervalSub\(l, r) subtracts the two intervals.

intervalMul\(l, r) multiplies the two intervals.

intervalDiv\(l, r) divides the two intervals.

Other Operations

const i1 = intervalOO\(+3, +11); // (+3, +11) const i2 = intervalCC\(+7,
+9);  // \[+7, +9\] intervalIntersection\(i1, i2);   // \[+7, +11)

intervalIntersection\(x, y) returns the intersection of two intervals.

const i1 = intervalOO\(+3, +9);  // (+3, +9) const i2 = intervalCC\(+7,
+11); // \[+7, +11\] intervalUnion\(i1, i2);          // (+3, +11\]

intervalUnion\(x, y) returns the union of two intervals.

intervalWidth\(intervalCC\(+4, +45)); // +41

intervalWidth\(i) returns the width of an interval.

intervalAbs\(intervalCC\(+1, +10)); // +10

intervalAbs\(i) returns the absolute value of an interval.
