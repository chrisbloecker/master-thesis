{-# LANGUAGE GADTs #-}

-- | The core module of Hive.
--
-- In this module we define the constructors and combinators for the Hive process algebra and also the interpreter.
--
-- For example usage check out the "Hive.Problem.Arithmetic" module.
module Process
  ( Process (..)
  , BasicProcess
  , Predicate
  , runProcess
  ) where

-------------------------------------------------------------------------------

import Control.Monad           (forM)
import Control.Concurrent      (forkIO)
import Control.Concurrent.MVar (MVar, newEmptyMVar, takeMVar, putMVar)

-------------------------------------------------------------------------------

type BasicProcess b = IO b
type Predicate a = Process a Bool

-- | The process algebra
data Process a b where
  Id         :: Process a a
  -- A constant process that returns a constant value
  Const      :: BasicProcess b -> Process a b
  -- A simple process that wraps a pure function
  Simple     :: (a -> BasicProcess b) -> Process a b
  -- A choice between two processes, based on the input value and another value that are combined into one value.
  -- This combinator inspects the input value and therefore cannot be an arrow.
  Choice     :: Predicate a -> Process a b -> Process a b -> Process a b
  -- Execute two processes sequentially
  Sequence   :: Process a c -> Process c b -> Process a b
  -- Executes one process multiple times and folds the results together
  --Multiple :: (Serializable b) => Process a c -> Int -> b -> Process (b, [c]) b -> Process a b
  -- Execute two processes in parallel and combine the results
  Parallel   :: Process a c -> Process a d -> Process (c, d) b -> Process a b
  -- Execute a list of processes in parallel and fold the results together
  Multilel   :: [Process a c] -> Process a b -> Process (b, [c]) b -> Process a b
  -- Repeat the execution of a process, like in a loop, as long as a given predicate holds.
  -- Unlike in imperative programming, we need a value that will be returned in case the predicate doesn't hold. In imperative programming this is represented implicitly by a (global) state.
  -- This combinator inspects the input value and therefore cannot be an arrow.
  Repetition :: Predicate a -> Process a a -> Process a a
  -- Maybe we want to split the data, run different actions on them and combine the results?
  --Split    :: (a -> (c, d)) -> Process c e -> Process d f -> Process (e, f) b -> Process a b
  -- Or maybe we want to split the data into many pieces?
  --Slice    :: (a -> [c]) -> [Process c d] -> b -> Process (b, [d]) b -> Process a b

-------------------------------------------------------------------------------
-- interpretation of Process structure
-------------------------------------------------------------------------------

-- | This is the interpreter for processes created using the Hive process algebra.
-- To run a process, we need a master node that can give us worker nodes to run the basic processes on.
-- Then we need a process that should be run as well as an input value to run the process on.
runProcess :: Process a b -> a -> IO b
runProcess Id x = return x

runProcess (Const bp) _ =
  bp

runProcess (Simple bp) x =
  bp x

{--
runProcess (Choice c acd pr p1 p2) x =
  runProcess (if pr (acd x c) then p1 else p2) x
--}
runProcess (Choice pr p1 p2) x = do
  b <- runProcess pr x
  runProcess (if b then p1 else p2) x

runProcess (Sequence p1 p2) x =
  runProcess p1 x >>= runProcess p2

runProcess (Parallel p1 p2 combinator) x = do
  mvar <- newEmptyMVar
  _ <- forkIO $ runProcessHelper p1 x mvar
  r2 <- runProcess p2 x
  r1 <- takeMVar mvar
  runProcess combinator (r1, r2)
{-- or alternatively:
runProcess (Parallel p1 p2 combinator) x = do
  runProcess (Split (\x -> (x,x)) p1 p2 combinator) x
--}

runProcess (Multilel ps foldinit fold) x = do
  mvars <- forM ps $ const newEmptyMVar
  mapM_ (\(comp, mvar) -> forkIO $ runProcessHelper comp x mvar) (ps `zip` mvars)
  ress  <- forM mvars takeMVar
  ib <- runProcess foldinit x
  runProcess fold (ib, ress)

{-- or alternatively:
runProcess (Multilel ps ib fold) x = do
  runProcess (Slice repeat ps ib fold) x
--}

{--
runProcess (Loop ib ic pr ba acc p) x = do
  if pr (acc x ic) then do
    x' <- runProcess p x
    runProcess (Loop x' (acc x ic) pr ba acc p) (ba x')
  else
    return ib
--}
runProcess rep@(Repetition pr p) x =
  runProcess (Choice pr (Sequence p rep) Id) x

{--
runProcess (Split split p1 p2 combinator) x = do
  let (xl, xr) = split x
  mvar <- newEmptyMVar
  _ <- forkIO $ runProcessHelper p1 xl mvar
  r2 <- runProcess p2 xr
  r1 <- takeMVar mvar
  runProcess combinator (r1, r2)

runProcess (Slice slice ps ib fold) x = do
  let pairs = ps `zip` slice x
  mvars <- forM pairs (const newEmptyMVar)
  mapM_ (\((proc, x'), mvar) -> forkIO $ runProcessHelper proc x' mvar) (pairs `zip` mvars)
  ress  <- forM mvars $ \mvar -> takeMVar mvar
  runProcess fold (ib, ress)
--}

-------------------------------------------------------------------------------

-- | A helper function to run processes in background.
-- The process helper will be spawned in a new local process and put its result into an MVar.
runProcessHelper :: Process a b -> a -> MVar b -> IO ()
runProcessHelper p x mvar = putMVar mvar =<< runProcess p x