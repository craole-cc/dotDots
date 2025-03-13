"use strict";(self["webpackChunkdesktop_wallet"]=self["webpackChunkdesktop_wallet"]||[]).push([[1292],{96767:function(t,e,a){a.d(e,{Z:function(){return p}});var o=function(){var t=this,e=t._self._c;t._self._setupProxy;return e("div",{staticClass:"t-crypto_backup_benefits"},[e("p",[t._v(t._s(t.$t("cryptoBackup.backupBenefits.backingUpAllowsYouTo")))]),e("ul",{staticClass:"list-disc mx-4"},t._l(t.benefits,(function(a,o){return e("li",{key:`benefit-${o+1}`},[t._v(t._s(a))])})),0),e("br"),e("i18n",{attrs:{path:"termsOfService.thisServiceIsProvidedByOperaNorway",tag:"p"},scopedSlots:t._u([{key:"operaTerms",fn:function(){return[e("a",{staticClass:"cursor-pointer t-tos-opera_norway-click text-brand-primary",on:{click:function(e){return t.$platform.createNewTab({url:"https://legal.opera.com/terms/"})}}},[t._v(t._s(t.$t("termsOfService.operaTerms")))])]},proxy:!0}])})],1)},r=[],n=a(20144),s=n.ZP.extend({name:"CryptoBackupBenefitsText",computed:{benefits(){return[this.$t("cryptoBackup.backupBenefits.restoreWallet"),this.$t("cryptoBackup.backupBenefits.haveSeedPhraseBackedUp"),this.$t("cryptoBackup.backupBenefits.checkPhrase")]}}}),i=s,l=a(1001),c=(0,l.Z)(i,o,r,!1,null,null,null),p=c.exports},93091:function(t,e,a){a.d(e,{Z:function(){return p}});var o=function(){var t=this,e=t._self._c;t._self._setupProxy;return e("footer",{staticClass:"w-full",class:[t.textColor,t.textSize]},[e("i18n",{attrs:{path:"termsOfService.operaWalletByBlueboard",tag:"p"},scopedSlots:t._u([{key:"blueboardTermsOfService",fn:function(){return[e("a",{staticClass:"t-tos_footer-tos_link text-brand-primary",on:{click:function(e){return t.$platform.createNewTab({url:"https://www.opera.com/terms/crypto"})}}},[t._v(t._s(t.$t("termsOfService.blueboardTermsOfService")))])]},proxy:!0}])})],1)},r=[],n=a(20144),s=n.ZP.extend({name:"TermsOfServiceFooter",props:{textColor:{required:!0,type:String},textSize:{default:"text-xs",required:!1,type:String}}}),i=s,l=a(1001),c=(0,l.Z)(i,o,r,!1,null,null,null),p=c.exports},31292:function(t,e,a){a.r(e),a.d(e,{default:function(){return S}});var o=function(){var t=this,e=t._self._c;t._self._setupProxy;return e("div",{staticClass:"bg-65 bg-blurred-background bg-cover flex flex-col flex-grow h-full justify-between overflow-x-hidden"},[e("div",{staticClass:"flex flex-col grow justify-between mb-14 mt-24 mx-10"},[e("div",{staticClass:"mx-[30px]"},[e("i18n",{staticClass:"font-semibold text-4xl text-left text-yellow",attrs:{path:"views.welcomeView.walletSloganV2",tag:"p"},scopedSlots:t._u([{key:"enable",fn:function(){return[e("span",{staticClass:"text-white"},[t.$i18n.locale.startsWith("zh")?e("br"):t._e(),t._v(" "+t._s(t.$t("general.enable"))+" ")])]},proxy:!0}])}),e("i18n",{staticClass:"mt-7.5 text-dark-N77 text-left text-sm",attrs:{path:"views.welcomeView.supportedTechnologies",tag:"p"},scopedSlots:t._u([{key:"howManyMoreBlockchains",fn:function(){return[e("a",{staticClass:"text-brand-primary",on:{click:function(e){return t.$platform.createNewTab({url:t.SUPPORTED_BLOCKCHAINS_URL})}}},[t._v(" "+t._s(t.$t("views.welcomeView.nMoreBlockchains",{n:t.howManyMoreBlockchains}))+" ")])]},proxy:!0}])})],1)]),t.showOnboardingPopup?e("wallet-onboarding-popup",{attrs:{callback:t.walletOnboardingPopupCallback,mode:t.onboardingType,"no-wallet-backup-found":t.noWalletBackupFound},on:{hide:function(e){t.showOnboardingPopup=!1,t.noWalletBackupFound=!1}}}):t._e(),e("img",{staticClass:"w-full",attrs:{alt:"",src:a(57650)}}),e("div",{staticClass:"flex flex-col grow justify-between mx-10"},[e("div",{staticClass:"flex flex-col mt-4"},[e("primary-button",{staticClass:"flex-1 my-8 t-welcome_view-create_new_wallet",attrs:{title:t.$t("general.createNewWallet")},on:{click:function(e){return t.initWalletOnboarding("create")}}}),e("outlined-button",{staticClass:"flex-1 mb-8 t-welcome_view-restore_wallet",attrs:{title:t.$t("views.welcomeView.iAlreadyHaveWallet")},on:{click:function(e){return t.initWalletOnboarding("restore")}}})],1)]),e("terms-of-service-footer",{staticClass:"px-10 py-5",attrs:{"text-color":"text-text-alt"}})],1)},r=[],n=(a(57658),a(46686)),s=a(75546),i=a(20629),l=a(13891),c=a(25319),p=a(69790),u=a(93091),d=a(20144),h=function(){var t=this,e=t._self._c;t._self._setupProxy;return e("transition",{attrs:{name:"fade"}},[e("div",{staticClass:"bg-black bg-opacity-50 fixed flex inset-0 items-center justify-center z-10",class:`t-wallet_onboarding_popup-${t.mode}-background`},[e("div",{staticClass:"bg-modal flex flex-col items-center m-12 max-w-screen-sm px-9 py-10 rounded-2xl space-y-12 w-full",class:`t-wallet_onboarding_popup-${t.mode}`},[e("div",{staticClass:"flex flex-col relative w-full"},[e("img",{staticClass:"-right-3 -top-4 absolute cursor-pointer h-3 w-3",class:`t-wallet_onboarding_popup-${t.mode}-close`,attrs:{src:a(50420)},on:{click:function(e){return t.$emit("hide")}}}),e("h2",{staticClass:"break-words font-bold max-w-xs text-center text-xl"},[t._v(" "+t._s(t.popupContentConfig.heading)+" ")])]),"cryptoBackupBenefitsText"===t.popupContentConfig.description?e("crypto-backup-benefits-text",{staticClass:"leading-5 max-w-xs text-dark-N77 text-sm whitespace-pre-line"}):t.popupContentConfig.description?e("p",{staticClass:"leading-5 max-w-xs text-dark-N77 text-sm whitespace-pre-line"},[t._v(" "+t._s(t.popupContentConfig.description)+" ")]):t._e(),e("div",{staticClass:"flex flex-col items-center w-full"},[e("primary-button",{class:`flex-1 t-wallet_onboarding_popup-${t.mode}-use_opera_account`,attrs:{icon:"",title:t.popupContentConfig.primaryButton},on:{click:t.operaAccountClick}},[e("img",{staticClass:"mr-3.5",attrs:{src:a(11075)}})]),t.popupContentConfig.secondaryButton?e("p",{staticClass:"my-4"},[t._v(t._s(t.$t("general.or")))]):t._e(),t.popupContentConfig.secondaryButton?e("outlined-button",{class:`flex-1 t-wallet_onboarding_popup-${t.mode}-non_custodial_wallet`,attrs:{title:t.popupContentConfig.secondaryButton},on:{click:t.manualBackup}}):t._e()],1)],1)])])},w=[],g=a(96767),f=a(39624),m=d.ZP.extend({name:"WalletOnboardingPopup",components:{CryptoBackupBenefitsText:g.Z,OutlinedButton:l.Z,PrimaryButton:c.Z},props:{callback:{required:!0,type:Function},mode:{required:!0,type:String},noWalletBackupFound:{default:!1,type:Boolean}},computed:{...(0,i.Se)({operaServicesSupported:"operaServicesSupported"}),popupContentConfig(){return new Map([["noWalletBackupFound",{description:this.$t("cryptoBackup.noWalletFoundInfo"),heading:this.$t("general.noWalletFound"),primaryButton:this.$t("general.createNewWallet"),secondaryButton:""}],["create",{description:"cryptoBackupBenefitsText",heading:this.$t("general.walletBackup"),primaryButton:this.$t("general.backupWithOpera"),secondaryButton:this.$t("general.manualBackup")}],["restore",{description:"",heading:this.$t("general.restoreYourWallet"),primaryButton:this.$t("operaAccount.useOperaAccount"),secondaryButton:this.$t("general.useRecoveryPhrase")}]]).get(this.textVariant)},textVariant(){return this.noWalletBackupFound?"noWalletBackupFound":this.mode}},methods:{manualBackup(){p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_create_manual"),this.callback("nonCustodial")},operaAccountClick(){p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_create_opera"),this.operaServicesSupported?this.callback(s.SupportedOperaServices.OperaAccount):this.$popupManager={cancelButtonTitle:this.$t("general.cancel"),confirmButtonTitle:this.$t("general.update"),confirmedCallback:()=>this.$platform.createNewTab({url:f["default"].browserUpdateURI}),description:this.$t("general.operaBrowserUpdateRequestDescription",{version:98}),popupType:"info",title:this.$t("general.operaBrowserUpdateRequestTitle"),type:"general"}}}}),k=m,b=a(1001),y=(0,b.Z)(k,h,w,!1,null,null,null),C=y.exports,v=a(9502),_=a(25108),A=d.ZP.extend({name:"WelcomeView",components:{OutlinedButton:l.Z,PrimaryButton:c.Z,TermsOfServiceFooter:u.Z,WalletOnboardingPopup:C},beforeRouteEnter(t,e,a){a((t=>{t.setOnboardingOngoing(!1)}))},beforeRouteLeave(t,e,a){this.setOnboardingOngoing(!0),a()},data(){return{SUPPORTED_BLOCKCHAINS_URL:"https://help.opera.com/en/opera-wallet-supported-crypto-assets/",noWalletBackupFound:!1,onboardingType:null,showCreateNewWalletPopup:!1,showOnboardingPopup:!1,walletOnboardingPopupCallback:null}},computed:{...(0,i.Se)({authAborted:"authAborted",isOperaAccountLoggedIn:"isOperaAccountLoggedIn",isOperaServiceActive:"isOperaServiceActive",mainNetworks:"mainNetworks",operaAccount:"operaAccount",operaServicesSupported:"operaServicesSupported",visibleNetworks:"visibleNetworks"}),howManyMoreBlockchains(){const t=[n.CHAINS.BTC,n.CHAINS.ETH,n.CHAINS.BNB,n.CHAINS.SOLANA];return this.mainNetworks.length-t.length},isOperaAccountActive(){return this.isOperaServiceActive(s.SupportedOperaServices.OperaAccount)},onboardingTypeWalletModeMap(){return new Map([["create",t=>this.createNewWallet(t)],["restore",t=>this.restoreWallet(t)]])}},watch:{activeOperaServices:{deep:!0,handler(t,e){t.operaAccount&&!e.operaAccount&&this.createNewWallet("operaAccount")}},authAborted(t){t&&this.$progress.hide()}},async mounted(){this.$root.$on("continueOnboardingWithOperaAccount",(()=>{const{onboardingType:t,onboardingTypeWalletModeMap:e}=this;if(e.has(t)){const a=e.get(t);a("operaAccount")}}))},methods:{...(0,i.nv)(["addWalletBackup","cleanWalletData","getAccounts","getPerpetualCashbackConnectionStatus","getWalletSeedphraseBackup","getWalletBackups","reAuthenticateOperaAccount","setCashbackActive","setMigratingWallet","setOnboardingOngoing","setOperaServiceActive","stopOperaAccountAuthorization"]),async createNewWallet(t="nonCustodial"){await p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_create_btn");let e=[];if("operaAccount"===t){if(this.isOperaAccountLoggedIn&&(e=await this.getWalletBackups(),e.length)){const t=e.at(0).evm_address;return this.showBackupFailedPopup(this.$t("cryptoBackup.operaAccountAlreadyHasWalletBackup",{email:this.operaAccount.email,walletAddress:v.Z.elideAddress(t)}))}if(!this.isOperaAccountActive)return this.showOperaAccountAuthPopup()}try{this.$progress.show(),this.$progress.inflate("low"),this.$authenticator.lockAuthenticatorWithPassword(),await this.$wallet.createNewWallet(),await this.cleanWalletData(),await this.getAccounts(),await p.Z.sendStatsEvent(p.Z.types.CLICK,"wallet_created"),"operaAccount"===t?(e.length||await this.addWalletBackup(),await this.getPerpetualCashbackConnectionStatus()&&await this.setCashbackActive(),this.showAckPopup(),this.$authenticator.clearSecretAndUnlockAuthenticator(),await this.$router.push({name:"Overview"})):"nonCustodial"===t&&await this.$router.push({name:"BackupRevealWarning"})}catch(a){_.error("WALLET CREATE ERROR",a),this.$authenticator.clearSecretAndUnlockAuthenticator(),this.$errorReporter.reportError(a),await p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_setpwd_fail",{error:"Error creating wallet"})}finally{this.stopOperaAccountAuthorization(),this.$progress.hide()}},initWalletOnboarding(t){const e=this.onboardingTypeWalletModeMap.get(t);this.showOnboardingPopup=!0,this.onboardingType=t,this.walletOnboardingPopupCallback=e},async restoreWallet(t="nonCustodial"){if("nonCustodial"===t)return this.$router.push({name:"Restore"});if("operaAccount"===t&&!this.isOperaAccountActive)return this.showOperaAccountAuthPopup();let e;try{this.$progress.show(),this.$progress.inflate("low");const t=await this.getWalletBackups();if(!t.length)return this.$progress.hide(),this.setNoWalletBackupFound();const a=t[0].evm_address;this.$authenticator.lockAuthenticatorWithPassword(),e=await this.getWalletSeedphraseBackup(a).then((t=>t)),await this.getPerpetualCashbackConnectionStatus()&&await this.setCashbackActive()}catch(a){if(_.error("WALLET RESTORE ERROR",a),a.isAxiosError){const e=a;e.code===s.f.TOKEN_EXPIRED&&await this.tryToReAuthenticateUser((()=>this.restoreWallet(t)))}return}finally{this.$progress.hide()}try{await this.$wallet.importWallet({id:"",mnemonic:e}),await this.cleanWalletData(),await this.getAccounts(),await this.setOperaServiceActive({active:!0,serviceName:s.SupportedOperaServices.CryptoBackup}),this.showAckPopup(),await this.$router.push({name:"Overview"}),p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_restore_phr_suc")}catch(a){_.error(a),this.$errorReporter.reportError(a),p.Z.sendStatsEvent(p.Z.types.CLICK,"wt_restore_fail_suc",{error:a.toString()})}finally{this.stopOperaAccountAuthorization(),this.$authenticator.clearSecretAndUnlockAuthenticator(),this.$progress.hide()}},setNoWalletBackupFound(){this.noWalletBackupFound=!0,this.onboardingType="create",this.walletOnboardingPopupCallback=()=>this.createNewWallet("operaAccount")},showAckPopup(){this.$popupManager={description:this.$t("operaAccount.walletHasBeenSetUp"),title:this.$t("general.youAreAllSet"),type:"ack"}},showBackupFailedPopup(t){this.$popupManager={confirmButtonTitle:this.$t("general.ok"),description:t.message??t,popupType:"error",title:this.$t("cryptoBackup.backupFailed"),type:"general"}},showOperaAccountAuthPopup(){this.$popupManager={type:"operaAccountAuth"}},async tryToReAuthenticateUser(t){await this.reAuthenticateOperaAccount(),t()}}}),x=A,B=(0,b.Z)(x,o,r,!1,null,null,null),S=B.exports},57650:function(t,e,a){t.exports=a.p+"img/welcome_page_coin_logos.0d4e909e.webp"}}]);