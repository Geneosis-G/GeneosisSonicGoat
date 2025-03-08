class SonicGoatComponent extends GGMutatorComponent;

var int mMaterialIndex;
var Material mAngelMaterial;
var Material mDevilMaterial;

var bool isCharging;
var float mChargeTime;
var float mMaxChargeTime;
var float oldFallingTime;
var float lastSpeed;

var float mSpeedMultiplier;

var MaterialInstanceConstant mMaterialInstanceConstant;

var SoundCue mChargeSoundCue;
var AudioComponent mAC;

var name mBallAnimationName;

var ParticleSystem mStreakParticleTemplate;
var ParticleSystem mRibbonParticleTemplate;
var ParticleSystemComponent mStreakParticle;
var ParticleSystemComponent mRibbonParticle;

var float dashSpeed;
var float dashDuration;
var bool dashing;
var float oldStrafeSpeed;
var float oldWalkSpeed;
var float oldReverseSpeed;
var float oldSprintSpeed;
var vector oldVelocity;

var GGGoat gMe;
var GGMutator myMut;

var bool isAiming;
var GGPawn myTarget;

var bool isCollectingRings;
var int nbRingsCollected;
var SoundCue dropRingsSound;

var bool isSuperSonic;
var bool isSuperSonicForever;
var bool isJumpPressed;
var int nbRingsForSuperSonic;
var float superSonicMultiplier;
var float ringConsumeFrequency;
var ParticleSystem superSonicGlowTemplate;
var ParticleSystemComponent superSonicGlow;
var ParticleSystem superSonicRibbonTemplate;
var ParticleSystemComponent superSonicRibbon;
var ParticleSystem superSonicTransformTemplate;
var SoundCue superSonicTransformSound;

var bool isShadow;
var ParticleSystem shadowRibbonTemplate;
var ParticleSystemComponent shadowRibbon;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer( goat, owningMutator );

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		gMe.mSprintSpeed = gMe.default.mSprintSpeed * 4.f;
		gMe.mCanRagdollByVelocityOrImpact=false;

		superSonicGlow = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( superSonicGlowTemplate, gMe.mesh, 'JetPackSocket', true );
		superSonicGlow.SetHidden(true);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		//myMut.WorldInfo.Game.Broadcast(myMut, "newKey=" $ newKey);
		if(localInput.IsKeyIsPressed("GBA_FreeLook", string( newKey )))
		{
			ToggleCharge();
		}

		if(localInput.IsKeyIsPressed("GBA_AbilityAuto", string( newKey )))
		{
			StopCharge(true);
		}

		if(newKey == 'MiddleMouseButton' || newKey == 'XboxTypeS_LeftThumbStick')
		{
			ToggleAiming();
		}

		if(localInput.IsKeyIsPressed("GBA_Baa", string( newKey )))
		{
			gMe.SetTimer(1.f, false, NameOf(ToggleSuperSonic), self);
		}

		if(localInput.IsKeyIsPressed("GBA_Jump", string( newKey )))
		{
			isJumpPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("GBA_Baa", string( newKey )))
		{
			if(gMe.IsTimerActive(NameOf(ToggleSuperSonic), self))
			{
				gMe.ClearTimer(NameOf(ToggleSuperSonic), self);
			}
		}

		if(localInput.IsKeyIsPressed("GBA_Jump", string( newKey )))
		{
			isJumpPressed=false;
		}
	}
}

simulated event TickMutatorComponent( float delta )
{
	local color darkBlue, blue, darkYellow, yellow, darkBlack, black, idleColor, spinColor;
	local LinearColor newColor;
	local rotator newRot;
	local name attachSock;

	if(isCharging && gMe.mIsRagdoll)
	{
		if(gMe.mAnimNodeSlot.GetPlayedAnimation() == mBallAnimationName)
		{
			gMe.mAnimNodeSlot.StopCustomAnim(0.3f);
		}
		StopCharge();
	}

	UpdateSpeedMultiplier(delta);

	if(gMe.Mesh.GetMaterial(0) == mDevilMaterial)
	{
		ActivateShadow();
	}
	if(MaterialInstanceConstant(gMe.Mesh.GetMaterial(0)) == none)
	{
		gMe.mesh.SetMaterial( mMaterialIndex, mAngelMaterial );
		mMaterialInstanceConstant = gMe.mesh.CreateAndSetMaterialInstanceConstant( mMaterialIndex );
	}
	else if(MaterialInstanceConstant(gMe.Mesh.GetMaterial(0)) != mMaterialInstanceConstant)
	{
		mMaterialInstanceConstant=MaterialInstanceConstant(gMe.Mesh.GetMaterial(0));
	}
	darkBlue = MakeColor( 8, 31, 171, 255 );
	blue = MakeColor( 65, 105, 255, 255 );
	darkYellow = MakeColor( 175, 130, 0, 255 );
	yellow = MakeColor( 240, 200, 65, 255 );
	darkBlack = MakeColor( 0, 0, 0, 255 );
	black = MakeColor( 3, 3, 2, 255 );
	if(isSuperSonic)
	{
		idleColor=darkYellow;
		spinColor=yellow;
	}
	else
	{
		if(isShadow)
		{
			idleColor=darkBlack;
			spinColor=black;
		}
		else
		{
			idleColor=darkBlue;
			spinColor=blue;
		}
	}

	newColor = ColorToLinearColor( LerpColor( idleColor, spinColor, mSpeedMultiplier) );
	mMaterialInstanceConstant.SetVectorParameterValue( 'color', newColor );

	if( isCharging )
	{
		if(gMe.Physics == PHYS_Falling)
		{
			gMe.SetRotation(rot(0, 1, 0) * gMe.Rotation.Yaw);
		}

		if(gMe.mAnimNodeSlot.GetPlayedAnimation() != mBallAnimationName)
		{
			gMe.mAnimNodeSlot.PlayCustomAnim( mBallAnimationName, mSpeedMultiplier * 5, 0.0f, 0.0f, true, false);
		}
		gMe.mAnimNodeSlot.GetCustomAnimNodeSeq().Rate = mSpeedMultiplier * 5;

		if(isAiming)
		{
			myTarget=GetClosestVisiblePawn();
			if(myTarget != none)
			{
				newRot=gMe.Rotation;
				newRot.Yaw=Rotator(Normal(GetLocation(myTarget) - GetLocation(gMe))).Yaw;
				gMe.SetRotation(newRot);
			}
		}
		else
		{
			myTarget=none;
		}

		if(VSize(gMe.Velocity) < lastSpeed)
		{
			if(gMe.mIsSprinting)
			{
				if(gMe.Physics == PHYS_Walking || gMe.Physics == PHYS_Spider || gMe.Physics == PHYS_WallRun)
				{
					gMe.Velocity=Normal(gMe.Velocity)*lastSpeed;
				}
			}
		}
		lastSpeed=VSize(gMe.Velocity);
	}
	else
	{
		lastSpeed=0.f;
	}

	if(	mStreakParticle == none )
	{
		attachSock='ButtSocket';
		if(gMe.mesh.GetSocketByName(attachSock) != none)
		{
			mStreakParticle = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( mStreakParticleTemplate, gMe.mesh, attachSock, true );
		}
		else
		{
			mStreakParticle = gMe.WorldInfo.MyEmitterPool.SpawnEmitter(mStreakParticleTemplate, gMe.Location, gMe.Rotation, gMe);
		}
	}
	if(mStreakParticle != none)
	{
		if(dashing)
		{
			mStreakParticle.SetHidden( false );
		}
		else
		{
			mStreakParticle.SetHidden( true );
		}
	}

	if(	mRibbonParticle == none )
	{
		attachSock='BlueStreakRibbon';
		if(gMe.mesh.GetSocketByName(attachSock) != none)
		{
			mRibbonParticle = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( mRibbonParticleTemplate, gMe.mesh, attachSock, true );
		}
		else
		{
			mRibbonParticle = gMe.WorldInfo.MyEmitterPool.SpawnEmitter(mRibbonParticleTemplate, gMe.Location, gMe.Rotation, gMe);
		}
	}
	if( superSonicRibbon == none )
	{
		attachSock='BlueStreakRibbon';
		if(gMe.mesh.GetSocketByName(attachSock) != none)
		{
			superSonicRibbon = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( superSonicRibbonTemplate, gMe.mesh, attachSock, true );
		}
		else
		{
			superSonicRibbon = gMe.WorldInfo.MyEmitterPool.SpawnEmitter(superSonicRibbonTemplate, gMe.Location, gMe.Rotation, gMe);
		}
	}
	if( shadowRibbon == none )
	{
		attachSock='BlueStreakRibbon';
		if(gMe.mesh.GetSocketByName(attachSock) != none)
		{
			shadowRibbon = gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( shadowRibbonTemplate, gMe.mesh, attachSock, true );
		}
		else
		{
			shadowRibbon = gMe.WorldInfo.MyEmitterPool.SpawnEmitter(shadowRibbonTemplate, gMe.Location, gMe.Rotation, gMe);
		}
	}
	if( mRibbonParticle != none)
	{
		if(isCharging)
		{
			if(isSuperSonic)
			{
				superSonicRibbon.SetHidden( false );
				mRibbonParticle.SetHidden( true );
				shadowRibbon.SetHidden( true );
			}
			else
			{
				if(isShadow)
				{
					shadowRibbon.SetHidden( false );
					mRibbonParticle.SetHidden( true );
					superSonicRibbon.SetHidden( true );
				}
				else
				{
					mRibbonParticle.SetHidden( false );
					superSonicRibbon.SetHidden( true );
					shadowRibbon.SetHidden( true );
				}
			}
		}
		else
		{
			mRibbonParticle.SetHidden( true );
			superSonicRibbon.SetHidden( true );
			shadowRibbon.SetHidden( true );
		}
	}

	//Air shield management
	if(isCharging)
	{
		if(isSuperSonic || isShadow)
		{
			AirShieldEffect();
		}
	}

	//super sonic hover ability
	if(isSuperSonic)
	{
		superSonicGlow.SetHidden(!isJumpPressed);
		if(gMe.Physics == PHYS_Falling && isJumpPressed && gMe.Velocity.Z<0)
		{
			gMe.Velocity.Z=0;
		}
	}
}

function GGPawn GetClosestVisiblePawn()
{
	local GGPawn gpawn, closestPawn;

	closestPawn=none;//Avoid warning for unassigned variable
	foreach gMe.VisibleCollidingActors(class'GGPawn', gpawn, 7500, gMe.Location)
	{
		if(gpawn != none && gpawn != gMe && gpawn.Controller != none)
		{
			if(closestPawn == none || (VSize(GetLocation(gpawn) - GetLocation(gMe)) < VSize(GetLocation(closestPawn) - GetLocation(gMe))))
			{
				closestPawn = gpawn;
			}
		}
	}

	return closestPawn;
}

function vector GetLocation(GGPawn gpawn)
{
	if(gpawn.mIsRagdoll)
	{
		return gpawn.Mesh.GetPosition();
	}
	else
	{
		return gpawn.Location;
	}
}

function PlayChargeSound()
{
	if( mAC == none || mAC.IsPendingKill() )
	{
		mAC = gMe.CreateAudioComponent( mChargeSoundCue, false );
	}
	if( mAC.IsPlaying() )
	{
		mAC.Stop();
	}
	mAC.PitchMultiplier = mAC.default.PitchMultiplier + mSpeedMultiplier;
	mAC.Play();

	if(isCharging)
	{
		gMe.SetTimer( 0.25, false, NameOf( PlayChargeSound ), self);
	}
}

function ToggleSuperSonic()
{
	if(!isCollectingRings)
		return;

	if(isSuperSonic)
	{
		ActivateSuperSonic(false);
	}
	else
	{
		if(nbRingsCollected >= nbRingsForSuperSonic)
		{
			ActivateSuperSonic(true);
		}
	}
}

function ToggleAiming()
{
	if(!isCharging)
		return;

	isAiming=!isAiming;
}

function ToggleCharge()
{
	if(isCharging)
	{
		StopCharge();
	}
	else
	{
		StartCharge();
	}
}

function StartCharge()
{
	if(!isCharging && !dashing && !gMe.mIsRagdoll && gMe.DrivenVehicle == none)
	{
		isCharging=true;
		oldStrafeSpeed=gMe.mStrafeSpeed;
		oldReverseSpeed=gMe.mReverseSpeed;
		oldFallingTime=gMe.mPlayFreeFallAnimThreshold;
		gMe.mStrafeSpeed=0.f;
		gMe.mReverseSpeed=0.f;
		gMe.mPlayFreeFallAnimThreshold=1000000;
		PlayChargeSound();
	}
}

function StopCharge(optional bool doDash)
{
	if(isCharging)
	{
		if( gMe.IsTimerActive( NameOf( PlayChargeSound ) ) )
		{
			gMe.ClearTimer( NameOf( PlayChargeSound ) );
		}
		gMe.mStrafeSpeed=oldStrafeSpeed;
		gMe.mReverseSpeed=oldReverseSpeed;
		gMe.mPlayFreeFallAnimThreshold=oldFallingTime;
		if(doDash)
		{
			Dash();
		}
		else if(gMe.mAnimNodeSlot.GetPlayedAnimation() == mBallAnimationName)
		{
			gMe.mAnimNodeSlot.StopCustomAnim(0.3f);
			isAiming=false;
		}
		isCharging=false;
	}
}

function UpdateSpeedMultiplier(float delta)
{
	if( isCharging )
	{
		mChargeTime+=delta;
		if(mChargeTime>mMaxChargeTime)
		{
			mChargeTime=mMaxChargeTime;
		}
		mSpeedMultiplier=mChargeTime/mMaxChargeTime;
	}
	else
	{
		mChargeTime=0.f;
		mSpeedMultiplier=0.f;
	}
}

function Dash()
{
	local vector direction, camLocation;
	local rotator camRotation;

	if(dashing || gMe.mIsRagdoll)
		return;

	if(myTarget != none)
	{
		direction=Normal(GetLocation(myTarget)-GetLocation(gMe));
	}
	else
	{
		if(GGPlayerControllerGame( gMe.Controller ) != none && (gMe.Physics == PHYS_Falling || gMe.Physics == PHYS_Flying))
		{
			GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
			direction=vector(camRotation);
			gMe.SetRotation(rot(0, 1, 0) * camRotation.Yaw);
		}
		else
		{
			direction=Normal(vector(gMe.Rotation));
		}
	}

	//myMut.WorldInfo.Game.Broadcast(myMut, "Dash!");
	oldStrafeSpeed=gMe.mStrafeSpeed;
	gMe.mStrafeSpeed=dashSpeed;
	oldWalkSpeed=gMe.mWalkSpeed;
	gMe.mWalkSpeed=dashSpeed;
	oldReverseSpeed=gMe.mReverseSpeed;
	gMe.mReverseSpeed=dashSpeed;
	oldSprintSpeed=gMe.mSprintSpeed;
	gMe.mSprintSpeed=dashSpeed;
	oldVelocity=gMe.Velocity;
	gMe.Velocity=Normal(direction)*dashSpeed;
	gMe.SetTimer( dashDuration*mSpeedMultiplier, false, NameOf( StopDash ), self);
	dashing=true;
}

function StopDash()
{
	//myMut.WorldInfo.Game.Broadcast(myMut, "Stop Dash");
	if(!dashing)
		return;

	gMe.mStrafeSpeed=oldStrafeSpeed;
	gMe.mWalkSpeed=oldWalkSpeed;
	gMe.mReverseSpeed=oldReverseSpeed;
	gMe.mSprintSpeed=oldSprintSpeed;
	if(isSuperSonic)
	{
		gMe.Velocity=Normal(gMe.Velocity)*gMe.mSprintSpeed;
	}
	else
	{
		gMe.Velocity=oldVelocity;
	}
	if(gMe.mAnimNodeSlot.GetPlayedAnimation() == mBallAnimationName)
	{
		gMe.mAnimNodeSlot.StopCustomAnim(0.3f);
	}
	dashing=false;
	isAiming=false;
}

function bool PickedUpRing()
{
	if(!isCollectingRings)
		return false;

	nbRingsCollected++;
	ShowRings();
	if(nbRingsCollected == 42)
	{
		class'SuperSonicGoat'.static.UnlockSuperSonicGoat();
	}
	return true;
}

function DropRings()
{
	local float ringsDropped;

	if(!isCollectingRings)
		return;

	ringsDropped=nbRingsCollected - (nbRingsCollected/2);
	if(ringsDropped > 0)
	{
		gMe.PlaySound(dropRingsSound);
	}
	SonicGoat(myMut).DropRings(ringsDropped, gMe);
	nbRingsCollected = nbRingsCollected / 2;
	ShowRings();
}

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == gMe && isRagdoll && !isSuperSonic)
	{
		DropRings();
	}
}

function ShowRings()
{
    local GGPlayerControllerGame gameController;
    local GGPlayerInputGame pInput;
    local string ringsStr;

    gameController = gMe.DrivenVehicle == none ? GGPlayerControllerGame( gMe.Controller ) : GGPlayerControllerGame( gMe.DrivenVehicle.Controller );
	pInput = GGPlayerInputGame(gameController.PlayerInput);
	if(gameController != none && pInput != none)
	{
		if(isCollectingRings)
		{
			ringsStr=nbRingsCollected @ "/" @ nbRingsForSuperSonic @ "Rings";
			if(!isSuperSonicForever)
			{
				if(isSuperSonic)
				{
					ringsStr=ringsStr@"(hold" @ pInput.GetKeyFromCommand("GBA_Baa") @ "to cancel transformation)";
				}
				else if(nbRingsCollected >= nbRingsForSuperSonic)
				{
					ringsStr=ringsStr@"(hold" @ pInput.GetKeyFromCommand("GBA_Baa") @ "to transform)";
				}
			}
		}

		gameController.AddHintLabelMessage( "RINGS", ringsStr, 0);
	}
}

function ActivateSuperSonic(bool activate, bool forever=false)
{
	if(isSuperSonic == activate || isSuperSonicForever)
		return;

	if(isCharging)
	{
		StopCharge();
	}

	isSuperSonicForever=forever;
	isSuperSonic=activate;
	if(isSuperSonic)
	{
		gMe.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( superSonicTransformTemplate, gMe.mesh, 'EffectSocket_01', true, );
		gMe.PlaySound( superSonicTransformSound );
		gMe.mSprintSpeed = gMe.mSprintSpeed * superSonicMultiplier;
		gMe.mWalkSpeed = gMe.mWalkSpeed * superSonicMultiplier;
		gMe.mStrafeSpeed = gMe.mStrafeSpeed * superSonicMultiplier;
		gMe.mReverseSpeed = gMe.mReverseSpeed * superSonicMultiplier;
		ConsumeRings();
	}
	else
	{
		gMe.mSprintSpeed = gMe.mSprintSpeed / superSonicMultiplier;
		gMe.mWalkSpeed = gMe.mWalkSpeed / superSonicMultiplier;
		gMe.mStrafeSpeed = gMe.mStrafeSpeed / superSonicMultiplier;
		gMe.mReverseSpeed = gMe.mReverseSpeed / superSonicMultiplier;
		if(gMe.IsTimerActive(NameOf( ConsumeRings ), self))
		{
			gMe.ClearTimer(NameOf( ConsumeRings ), self);
		}
	}
}

function ActivateShadow()
{
	isShadow=true;
	class'ShadowGoat'.static.UnlockShadowGoat();
}

function ConsumeRings()
{
	if(!isSuperSonic || !isCollectingRings)
		return;

	if(nbRingsCollected > 0)
	{
		nbRingsCollected--;
	}
	ShowRings();
	if(nbRingsCollected == 0)
	{
		ActivateSuperSonic(false);
	}
	else
	{
		gMe.SetTimer(ringConsumeFrequency, false, NameOf( ConsumeRings ), self);
	}
}

function AirShieldEffect()
{
	local GGAbility ability;
	local vector direction, loc;
	local float speed, radius, damage, impulse;

	ability = gMe.mAbilities[ EAT_Horn ];

	direction = Normal(gMe.Velocity);
	loc=gMe.Location + gMe.GetCollisionRadius()*direction;
	speed=VSize(gMe.Velocity);
	radius=sqrt(speed) + 20.f;
	damage=radius*4;
	impulse=radius*100;
	//myMut.WorldInfo.Game.Broadcast(myMut, "radius=" $ radius);

	gMe.DealDirectionalDamage( damage, radius, ability.mDamageTypeClass, impulse, loc, direction );
}

function NotifyOnPossess( Controller C, Pawn P )
{
	super.NotifyOnPossess(C, P);

	if(gMe == P)
	{
		ShowRings();
	}
}

function NotifyOnUnpossess( Controller C, Pawn P )
{
	super.NotifyOnUnpossess(C, P);

	if(gMe == P)
	{
		ShowRings();
	}
}

DefaultProperties
{
	mAngelMaterial=Material'goat.Materials.Goat_Mat_03'
	mDevilMaterial=Material'goat.Materials.Goat_Mat_02'
	mMaterialIndex=0

	mBallAnimationName=Spin

	dashSpeed=10000.f
	dashDuration=0.2f

	mMaxChargeTime=3.f
	mChargeTime=0.f

	mChargeSoundCue=SoundCue'Goat_Sound_UI.Cue.EnterPauseMenu_Cue'
	mStreakParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Spray_BlueStreak_01'
	mRibbonParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Bluestreak_Ribbon_01'
	dropRingsSound=SoundCue'SonicSounds.DropRingsCue'

	superSonicMultiplier=1.5f
	nbRingsForSuperSonic=42
	ringConsumeFrequency=5.f
	superSonicGlowTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Glow_01'
	superSonicRibbonTemplate=ParticleSystem'jetPack.Effects.JetThrust'
	superSonicTransformTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Levelup_01'
	superSonicTransformSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Level_Up_Cue'

	shadowRibbonTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'
}