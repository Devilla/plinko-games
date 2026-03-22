import type { Request, Response, NextFunction } from 'express';
import type { User } from '@prisma/client';
import type { UserInstance } from '../../user/user.service';
import { userManager } from '../../user/user.service';
import { BadRequestError } from '../../../errors';
import type { Mines } from './mines.service';
import { minesManager } from './mines.service';

interface PlayRoundRequestBody {
  selectedTileIndex: number;
  id: string;
}

declare module 'express' {
  interface Request {
    validatedRequest?: {
      selectedTileIndex: number;
      game: Mines;
      userInstance: UserInstance;
    };
  }
}

export const validatePlayRoundRequest = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const userId = (req.user as User).id;
  const userInstance = await userManager.getUser(userId);
  const user = userInstance.getUser();

  const game = await minesManager.getGame(user.id);

  if (!game?.getBet().active) {
    throw new BadRequestError('Game not found');
  }

  const { selectedTileIndex } = req.body as PlayRoundRequestBody;

  game.validatePlayRound(selectedTileIndex);

  req.validatedRequest = {
    selectedTileIndex,
    game,
    userInstance,
  };

  next();
};
