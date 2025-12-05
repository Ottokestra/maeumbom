export type CharacterId =
  | "sunny_flower"
  | "star_friend"
  | "heart_cat"
  | "idea_bulb"
  | "rain_cloud"
  | "fire_spirit"
  | "ghost_white"
  | "stone_gray"
  | "sloth_bear"
  | "devil_red"
  | "alien_green"
  | "cloud_white";

export interface CharacterMeta {
  id: CharacterId;
  labelKo: string;
  description: string;
  image: string;
}

import sunnyFlower from "../assets/characters/sunny_flower.svg";
import starFriend from "../assets/characters/star_friend.svg";
import heartCat from "../assets/characters/heart_cat.svg";
import ideaBulb from "../assets/characters/idea_bulb.svg";
import rainCloud from "../assets/characters/rain_cloud.svg";
import fireSpirit from "../assets/characters/fire_spirit.svg";
import ghostWhite from "../assets/characters/ghost_white.svg";
import stoneGray from "../assets/characters/stone_gray.svg";
import slothBear from "../assets/characters/sloth_bear.svg";
import devilRed from "../assets/characters/devil_red.svg";
import alienGreen from "../assets/characters/alien_green.svg";
import cloudWhite from "../assets/characters/cloud_white.svg";

export const CHARACTER_MAP: Record<CharacterId, CharacterMeta> = {
  sunny_flower: {
    id: "sunny_flower",
    labelKo: "햇살 해바라기",
    description: "기분 좋은 에너지 뿜뿜!",
    image: sunnyFlower,
  },
  star_friend: {
    id: "star_friend",
    labelKo: "별빛 친구",
    description: "밤하늘을 닮은 포근함.",
    image: starFriend,
  },
  heart_cat: {
    id: "heart_cat",
    labelKo: "하트 고양이",
    description: "따뜻한 위로를 건네는 친구.",
    image: heartCat,
  },
  idea_bulb: {
    id: "idea_bulb",
    labelKo: "아이디어 전구",
    description: "반짝이는 영감의 순간!",
    image: ideaBulb,
  },
  rain_cloud: {
    id: "rain_cloud",
    labelKo: "비 구름",
    description: "촉촉한 감성을 담은 구름.",
    image: rainCloud,
  },
  fire_spirit: {
    id: "fire_spirit",
    labelKo: "불꽃 정령",
    description: "열정 넘치는 파이어!",
    image: fireSpirit,
  },
  ghost_white: {
    id: "ghost_white",
    labelKo: "하얀 유령",
    description: "살랑이는 장난꾸러기.",
    image: ghostWhite,
  },
  stone_gray: {
    id: "stone_gray",
    labelKo: "돌멩이",
    description: "묵묵히 곁을 지켜주는 친구.",
    image: stoneGray,
  },
  sloth_bear: {
    id: "sloth_bear",
    labelKo: "늘보 곰",
    description: "천천히, 하지만 따뜻하게.",
    image: slothBear,
  },
  devil_red: {
    id: "devil_red",
    labelKo: "장난꾸러기 악동",
    description: "장난기 가득한 붉은 친구.",
    image: devilRed,
  },
  alien_green: {
    id: "alien_green",
    labelKo: "초록 외계인",
    description: "낯설지만 궁금한 친구.",
    image: alienGreen,
  },
  cloud_white: {
    id: "cloud_white",
    labelKo: "흰둥이 구름",
    description: "포근한 솜사탕 같은 존재.",
    image: cloudWhite,
  },
};

export function getCharacterMeta(id?: string): CharacterMeta | undefined {
  if (!id) return undefined;
  return CHARACTER_MAP[id as CharacterId];
}
