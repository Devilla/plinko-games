import { Router } from 'express';
import { isAuthenticated } from '../../../middlewares/auth.middleware';
import { validateBet } from '../../../middlewares/bet.middleware';
import { rateLimitBets } from '../../../middlewares/rateLimit.middleware';
import {
  cashOut,
  getActiveGame,
  playRound,
  startGame,
} from './mines.controller';
import { validatePlayRoundRequest } from './mines.middleware';

const minesRouter: Router = Router();

minesRouter.post(
  '/start',
  isAuthenticated,
  rateLimitBets({ maxBetsPerMinute: 30 }),
  validateBet,
  startGame
);
minesRouter.post(
  '/play-round',
  isAuthenticated,
  validatePlayRoundRequest,
  playRound
);
minesRouter.post('/cash-out', isAuthenticated, cashOut);
minesRouter.get('/active', isAuthenticated, getActiveGame);

export default minesRouter;
