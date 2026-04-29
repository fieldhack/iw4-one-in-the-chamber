init()
{
    level thread onPlayerConnect();
    level thread watchRoundEnd();
}

onPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);

        player.lives      = 3;
        player.eliminated = false;

        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");

        if (self.eliminated)
        {
            wait 0.05;
            self suicide();
            self iPrintLnBold("^1You have been eliminated!");
            continue;
        }

        self thread setupLoadout();
        self thread onKilledEnemy();
        self thread onDeath();

        // Start HUD thread only on first spawn
        if (!isdefined(self.livesHud))
        {
            self thread showLivesHUD();
            self thread showFinalHUD();
        }
    }
}

setupLoadout()
{
    self endon("death");
    self endon("disconnect");

    if (self.pers["isBot"])
        wait 0.5;
    else
        wait 0.15;

    self takeAllWeapons();
    wait 0.05;

    if (!self hasWeapon("coltanaconda_mp"))
        self giveWeapon("coltanaconda_mp");

    self setWeaponAmmoClip("coltanaconda_mp", 1);
    self setWeaponAmmoStock("coltanaconda_mp", 0);
    self switchToWeapon("coltanaconda_mp");

    if (self.pers["isBot"])
        self thread enforceLoadout();
}

enforceLoadout()
{
    self endon("death");
    self endon("disconnect");

    checks = 0;
    while (checks < 5)
    {
        wait 0.2;
        checks++;

        currentWeapon = self getCurrentWeapon();

        if (!self hasWeapon("coltanaconda_mp") || currentWeapon == "none_mp" || currentWeapon == "none")
        {
            self takeAllWeapons();
            wait 0.05;
            self giveWeapon("coltanaconda_mp");
            self setWeaponAmmoClip("coltanaconda_mp", 1);
            self setWeaponAmmoStock("coltanaconda_mp", 0);
            self switchToWeapon("coltanaconda_mp");
        }
    }
}v

onKilledEnemy()
{
    self endon("death");
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");
        
        if (!self hasWeapon("coltanaconda_mp"))
            continue;

        currentClip = self getWeaponAmmoClip("coltanaconda_mp");
        self setWeaponAmmoClip("coltanaconda_mp", currentClip + 1);

        //wait 0.05;

        if (!self hasWeapon("coltanaconda_mp"))
            continue;

        self switchToWeapon("coltanaconda_mp");
        self iPrintLnBold("^2+^71");
    }
}

onDeath()
{
    self endon("disconnect");

    self waittill("death");

    self.lives--;

    if (self.lives <= 0)
    {
        self.eliminated = true;
        self iPrintLnBold("^1ELIMINATED^7!");
        level thread checkLastManStanding();
    }
}

showLivesHUD()
{
    self endon("disconnect");

    // only create once
    if (!isdefined(self.livesHud))
    {
        self.livesHud            = newClientHudElem(self);
        self.livesHud.font       = "objective";
        self.livesHud.fontscale  = 1.5;
        self.livesHud.alignX     = "left";
        self.livesHud.alignY     = "top";
        self.livesHud.horzAlign  = "left";
        self.livesHud.vertAlign  = "top";
        self.livesHud.x          = 90;
        self.livesHud.y          = 5;
        self.livesHud.color      = (1, 1, 1);
        self.livesHud.alpha      = 1;
    }

    for (;;)
    {
        self.livesHud setText("Lives: ^:" + self.lives);
        wait 0.5;
    }
}

showFinalHUD()
{
    self endon("disconnect");

    // only create once
    if (!isdefined(self.finalHud))
    {
        self.finalHud            = newClientHudElem(self);
        self.finalHud.font       = "objective";
        self.finalHud.fontscale  = 1.5;
        self.finalHud.alignX     = "left";
        self.finalHud.alignY     = "top";
        self.finalHud.horzAlign  = "left";
        self.finalHud.vertAlign  = "top";
        self.finalHud.x          = 90;
        self.finalHud.y          = 30;
        self.finalHud.color      = (1, 1, 1);
        self.finalHud.alpha      = 0;
    }

    for (;;)
    {
        self.finalHud setText("^1ONLY TWO REMAIN^7!");
    	wait(0.5);
    }
}

checkLastManStanding()
{
    if (isdefined(level.roundEnding) && level.roundEnding)
        return;

    players = level.players;
    alivePlayers = [];

    foreach (player in players)
    {
        if (!player.eliminated)
            alivePlayers[alivePlayers.size] = player;
    }
    
    if (alivePlayers.size == 2)
    {
    	foreach (player in players)
        {
            if (isdefined(player.finalHud))
        	player.finalHud.alpha = 1;
        }
    }

    if (alivePlayers.size == 1)
    {
        level.roundEnding = true;

        winner = alivePlayers[0];

        foreach (player in players)
        {
            player.finalHud.alpha = 0;
            player.livesHud.alpha = 0;
 
	    player iPrintLnBold("^1" + winner.name + " ^7wins the round!");
        }
        
        wait 7.0;
        Exec("fast_restart");
    }
    else if (alivePlayers.size == 0)
    {
        level.roundEnding = true;

        foreach (player in players)
        {
            player iPrintLnBold("^3Draw^7! Everyone eliminated.");
            player.finalHud.alpha = 0;
        }
	
        wait 7.0;
        Exec("fast_restart");
    }
}

watchRoundEnd()
{
    for (;;)
    {
        level waittill("restarted");

        level.roundEnding = false;

        foreach (player in level.players)
        {
            player.lives      = 3;
            player.eliminated = false;
        }
    }
}