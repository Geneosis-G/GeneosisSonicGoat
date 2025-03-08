class SonicTheme extends GGMutator;

var SonicGoat mSonicMut;
var array<GGGoat> mGoats;

var SoundCue sonic_theme;
var SoundCue SANIC_theme;
var SoundCue stars_theme;
var AudioComponent sonicAC;
var AudioComponent SANICAC;
var AudioComponent starsAC;
var bool playTheme;
var bool oldPlayTheme;
var bool playSANIC;
var bool oldPlaySANIC;
var bool playStars;
var bool starsStarted;

var float mStarsLimit;

function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			mGoats.AddItem(goat);
			ClearTimer(NameOf(StartTheme));
			SetTimer(1.f, false, NameOf(StartTheme));
		}
	}

	super.ModifyPlayer( other );
}

function StartTheme()
{
	local SonicGoat sonicMut;

	if(mSonicMut == none)
	{
		foreach AllActors(class'SonicGoat', sonicMut)
		{
			mSonicMut=sonicMut;
			break;
		}
	}

	if(playTheme)
		return;

	playTheme = true;
}

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	MusicManager();
}

function MusicManager()
{
	ShouldPlaySANIC();
	ShouldPlayStars();

	if( sonicAC == none || sonicAC.IsPendingKill() )
	{
		sonicAC = CreateAudioComponent( sonic_theme, false );
	}
	if( SANICAC == none || SANICAC.IsPendingKill() )
	{
		SANICAC = CreateAudioComponent( SANIC_theme, false );
	}
	if( starsAC == none || starsAC.IsPendingKill() )
	{
		starsAC = CreateAudioComponent( stars_theme, false );
	}

	if( !sonicAC.IsPlaying() ||  !SANICAC.IsPlaying())
	{
		sonicAC.Stop();
		sonicAC.Play();
		SANICAC.Stop();
		SANICAC.Play();
		AutoAdjustVolume();
	}

	if(oldPlayTheme != playTheme)
	{
		StopSound(playTheme);
		if(playTheme)
		{
			if(playStars)
			{
				sonicAC.Play();
				starsStarted=true;
			}
		}
		else
		{
			if(starsAC.IsPlaying())
			{
				starsAC.Stop();
			}
			starsStarted=false;
		}
		AutoAdjustVolume();
	}
	else
	{
		if(playTheme)
		{
			if(!starsAC.IsPlaying() && playStars)
			{
				starsAC.FadeIn(2.f, 1.f);
				sonicAC.AdjustVolume(2.f, 0.f);
				SANICAC.AdjustVolume(2.f, 0.f);
				starsStarted=true;
			}
			if(!starsAC.IsPlaying() && (oldPlaySANIC != playSANIC || starsStarted))
			{
				starsStarted=false;
				if(playSANIC)
				{
					sonicAC.AdjustVolume(2.f, 0.f);
					SANICAC.AdjustVolume(2.f, 1.f);
				}
				else
				{
					sonicAC.AdjustVolume(2.f, 1.f);
					SANICAC.AdjustVolume(2.f, 0.f);
				}
			}
		}
	}

	oldPlaySANIC=playSANIC;
	oldPlayTheme=playTheme;
}

function ShouldPlaySANIC()
{
	local GGGoat goat;

	playSanic=false;
	foreach mGoats(goat)
	{
		if(mSonicMut == none || mSonicMut.sonicGoats.Find(goat) == INDEX_NONE)
			continue;

		if(VSize(goat.Velocity) > goat.mSprintSpeed * (9.f/10.f))
		{
			playSanic=true;
			break;
		}
	}
}

function ShouldPlayStars()
{
	local GGGoat goat;

	playStars=false;
	foreach mGoats(goat)
	{
		if(goat.Location.Z >= mStarsLimit)
		{
			playStars=true;
			break;
		}
	}
}

function AutoAdjustVolume()
{
	if(playTheme && !starsAC.IsPlaying())
	{
		if(playSANIC)
		{
			sonicAC.AdjustVolume(0.f, 0.f);
			SANICAC.AdjustVolume(0.f, 1.f);
		}
		else
		{
			sonicAC.AdjustVolume(0.f, 1.f);
			SANICAC.AdjustVolume(0.f, 0.f);
		}
	}
	else
	{
		sonicAC.AdjustVolume(0.f, 0.f);
		SANICAC.AdjustVolume(0.f, 0.f);
	}
}

function SetPlayTheme(bool play)
{
	if(playTheme == play)
	{
		return;
	}

	playTheme=play;
}

simulated function StopSound(bool stop)
{
	local GGPlayerControllerBase goatPC;
	local GGProfileSettings profile;

	goatPC=GGPlayerControllerBase( GetALocalPlayerController() );
	profile = goatPC.mProfileSettings;

	if(stop)
	{
		goatPC.SetAudioGroupVolume( 'Music', 0.f);
	}
	else
	{
		goatPC.SetAudioGroupVolume( 'Music', profile.GetMusicVolume());
	}
}

DefaultProperties
{
	mStarsLimit=10000.f

	sonic_theme=SoundCue'SonicSounds.SonicThemeCue'
	SANIC_theme=SoundCue'SonicSounds.SANICThemeCue'
	stars_theme=SoundCue'SonicSounds.StarsThemeCue'
}