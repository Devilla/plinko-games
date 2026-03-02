import { Router } from 'express';
import { verifyMe } from '../../../middlewares/bet.middleware';
import { getBet, getBets } from './bets.controller';

const betsRouter: Router = Router();

betsRouter.get('/', getBets);
betsRouter.get('/:betId', verifyMe, getBet);

export default betsRouter;
