class ShadowGoat extends GGMutator
	config(Geneosis);

var array<GGGoat> shadowGoats;
var config bool isShadowUnlocked;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	//Function not called on custom mutators for now so this is not working
	return default.isShadowUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockShadowGoat()
{
	if(!default.isShadowUnlocked)
	{
		PostJuice( "Unlocked Shadow Goat" );
		default.isShadowUnlocked=true;
		static.StaticSaveConfig();
	}
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			if(!default.isShadowUnlocked)
			{
				DisplayLockMessage();
			}
			else
			{
				shadowGoats.AddItem(goat);
				ClearTimer(NameOf(InitShadows));
				SetTimer(1.f, false, NameOf(InitShadows));
			}
		}
	}
	
	super.ModifyPlayer( other );
}

function InitShadows()
{
	local SonicGoat sonic;
	local GGGoat goat;
	
	//Find Sonic Goat mutator
	foreach AllActors(class'SonicGoat', sonic)
	{
		if(sonic != none)
		{
			break;
		}
	}
	
	if(sonic == none)
	{
		DisplayUnavailableMessage();
		return;
	}
	
	//Activate shadow mode
	foreach shadowGoats(goat)
	{
		sonic.InitShadows(goat);
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "Shadow Goat only works if combined with Sonic Goat.");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

function DisplayLockMessage()
{
	ClearTimer(NameOf(DisplayLockMessage));
	WorldInfo.Game.Broadcast(self, "Shadow Goat Locked :( Find the Shadow Easter Egg to unlock it.");
	SetTimer(3.f, false, NameOf(DisplayLockMessage));
}

DefaultProperties
{
	
}