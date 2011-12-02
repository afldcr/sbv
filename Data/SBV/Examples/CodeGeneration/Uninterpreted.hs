-----------------------------------------------------------------------------
-- |
-- Module      :  Data.SBV.Examples.CodeGeneration.Uninterpreted
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-- Demonstrates the use of uninterpreted functions for the purposes of
-- code generation. This facility is important when we want to take
-- advantage of native libraries in the target platform, or when we'd
-- like to hand-generate code for certain functions for various
-- purposes, such as efficiency, or reliability.
-----------------------------------------------------------------------------

module Data.SBV.Examples.CodeGeneration.Uninterpreted where

import Data.SBV

-- | A definition of shiftLeft that can deal with variable length shifts.
-- (Note that the ``shiftL`` method from the 'Bits' class requires an 'Int' shift
-- amount.) Unfortunately, this'll generate rather clumsy C code due to the
-- use of tables etc., so we uninterpret it for code generation purposes
-- using the 'cgUninterpret' function.
shiftLeft :: SWord32 -> SWord32 -> SWord32
shiftLeft = cgUninterpret "SBV_SHIFTLEFT" cCode $ \x y ->
                select [x * literal (bit y) | y <- [0..(bitSize x) - 1]] (literal 0) y
  where -- the code we'd like SBV to spit out. Note that this is arbitrary
        -- C code. In this case we just used a macro, but it could be a function,
        -- include files etc. Also see 'cgAddDecl', 'cgAddLDFlags', and 'cgAddPrototype'
        -- functions.
        cCode = ["#define SBV_SHIFTLEFT(x, y) ((x) << (y))"]

-- | Test function that uses shiftLeft defined above. When used as a normal Haskell function
-- or in verification the definition is fully used, i.e., no uninterpretation happens. To wit,
-- we have:
--
--  >>> tstShiftLeft 3 4 5
--  224 :: SWord32
--
--  >>> prove $ \x y -> tstShiftLeft x y 0 .== x + y
--  Q.E.D.
tstShiftLeft ::  SWord32 -> SWord32 -> SWord32 -> SWord32
tstShiftLeft x y z = x `shiftLeft` z + y `shiftLeft` z

-- | Generate C code for "tstShiftLeft". In this case, SBV will *use* the user given definition
-- verbatim, instead of generating code for it. (Also see the functions 'cgAddDecl', 'cgAddLDFlags',
-- and 'cgAddPrototype'.)
genCCode :: IO ()
genCCode = compileToC Nothing "tst" $ do
                [x, y, z] <- cgInputArr 3 "vs"
                cgReturn $ tstShiftLeft x y z
