import { BaseApp } from "@zeppos/zml/base-app";

App(
  BaseApp({
    globalData: {},
    onCreate() {
      console.log("Radio FEM watch app created");
    },
    onDestroy() {
      console.log("Radio FEM watch app destroyed");
    },
  })
);
