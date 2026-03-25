import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, Dropdown, Input, Stack } from 'tgui-core/components';

type FamilyType = 'none' | 'member' | 'parent' | 'couple';
type SpeciesMode = 'ANY' | 'SAME_TYPE' | 'SPECIFIC_TYPE';
type GenderPref = 'any' | 'same' | 'opposite';
type AnatomyPref = 0 | 1 | 2;
type PolygamyMode = 0 | 1 | 2 | 3;
type RelativeRole = 0 | 1 | 2 | 3 | 4 | 5;

type DropdownOption<T extends string | number> = {
  value: T;
  displayText: string;
};

type FamilySettingsData = {
  familyType?: FamilyType;
  genderPreference?: GenderPref;
  speciesPreferenceMode?: SpeciesMode;
  preferredSpeciesTypes?: string[];
  preferredSpeciesAnatomy?: AnatomyPref;
  favoriteName?: string;
  age?: string;
  polygamyMode?: PolygamyMode;
  desiredRelativeRole?: RelativeRole;
  allowLowStatusMarriage?: number;
};

type BackendData = {
  familySettings?: FamilySettingsData;
  availableSpecies?: string[];
};

export const FamilySettingsPanel = () => {
  const { act, data } = useBackend<BackendData>();

  const settings = data.familySettings;
  const speciesList = data.availableSpecies || [];
  const isAdult = settings?.age === 'Adult';

  const [familyType, setFamilyType] = useState<FamilyType>('none');
  const [speciesPreferenceMode, setSpeciesPreferenceMode] =
    useState<SpeciesMode>('ANY');
  const [preferredSpeciesTypes, setPreferredSpeciesTypes] = useState<string[]>(
    []
  );
  const [preferredSpeciesAnatomy, setPreferredSpeciesAnatomy] =
    useState<AnatomyPref>(0);
  const [genderPreference, setGenderPreference] = useState<GenderPref>('any');
  const [favoriteName, setFavoriteName] = useState('');
  const [polygamyMode, setPolygamyMode] = useState<PolygamyMode>(0);
  const [desiredRelativeRole, setDesiredRelativeRole] =
    useState<RelativeRole>(0);
  const [allowLowStatusMarriage, setAllowLowStatusMarriage] = useState(0);
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    if (!settings || initialized) {
      return;
    }

    setFamilyType(settings.familyType ?? 'none');
    setSpeciesPreferenceMode(settings.speciesPreferenceMode ?? 'ANY');
    setPreferredSpeciesTypes(
      Array.isArray(settings.preferredSpeciesTypes)
        ? settings.preferredSpeciesTypes
        : []
    );
    setPreferredSpeciesAnatomy(settings.preferredSpeciesAnatomy ?? 0);
    setGenderPreference(settings.genderPreference ?? 'any');
    setFavoriteName(settings.favoriteName ?? '');
    setPolygamyMode(settings.polygamyMode ?? 0);
    setDesiredRelativeRole(settings.desiredRelativeRole ?? 0);
    setAllowLowStatusMarriage(settings.allowLowStatusMarriage ?? 0);
    setInitialized(true);
  }, [settings, initialized]);

  useEffect(() => {
    if (isAdult) {
      if (familyType === 'parent') {
        setFamilyType('member');
      }
      if (desiredRelativeRole === 2) {
        setDesiredRelativeRole(0);
      }
    }
  }, [isAdult, familyType, desiredRelativeRole]);

  const hintStyle = {
    padding: '6px 8px',
    fontSize: '12px',
    color: '#c9a04e',
    fontStyle: 'italic' as const,
    border: '1px solid #6b5a2e',
    marginTop: '6px',
  };

  const tooltips: Record<FamilyType, string> = {
    none: 'Персонаж не участвует в семейной системе.',
    member:
      'Вы попадёте в существующую семью как родственник: ребёнок, брат/сестра, родитель или дядя/тётя. Роль определяется возрастом. Супруг НЕ подбирается.',
    parent:
      'Система ищет вам супруга среди одиноких членов существующих семей. Если никого нет — вы основываете новый дом. Требуется совместимость по расе, полу и сословию.',
    couple:
      'Вы попадаете в очередь ожидания. Система подберёт партнёра среди других игроков с таким же режимом. Проверяются все параметры совместимости.',
  };

  const familyTypeOptions: DropdownOption<FamilyType>[] = isAdult
    ? [
        { value: 'none', displayText: 'Нет' },
        { value: 'member', displayText: 'Родственник' },
        { value: 'couple', displayText: 'Супружеская пара' },
      ]
    : [
        { value: 'none', displayText: 'Нет' },
        { value: 'member', displayText: 'Родственник' },
        { value: 'parent', displayText: 'Родитель / супруг' },
        { value: 'couple', displayText: 'Супружеская пара' },
      ];

  const speciesOptions: DropdownOption<SpeciesMode>[] = [
    { value: 'ANY', displayText: 'Любая' },
    { value: 'SAME_TYPE', displayText: 'Тот же тип' },
    { value: 'SPECIFIC_TYPE', displayText: 'Определенные расы' },
  ];

  const genderOptions: DropdownOption<GenderPref>[] = [
    { value: 'any', displayText: 'Любой' },
    { value: 'same', displayText: 'Тот же пол' },
    { value: 'opposite', displayText: 'Противоположный' },
  ];

  const anatomyOptions: DropdownOption<AnatomyPref>[] = [
    { value: 0, displayText: 'Без разницы' },
    { value: 1, displayText: 'Мужская анатомия' },
    { value: 2, displayText: 'Женская анатомия' },
  ];

  const polygamyOptions: DropdownOption<PolygamyMode>[] = [
    { value: 0, displayText: 'Отключено' },
    { value: 1, displayText: 'Несколько супругов' },
    { value: 2, displayText: 'Быть вторым супругом' },
    { value: 3, displayText: 'Обе опции' },
  ];

  const allRelativeRoleOptions: DropdownOption<RelativeRole>[] = [
    { value: 0, displayText: 'Любая роль' },
    { value: 1, displayText: 'Брат / сестра' },
    { value: 2, displayText: 'Родитель' },
    { value: 3, displayText: 'Ребёнок' },
    { value: 4, displayText: 'Дядя / тётя' },
  ];

  const relativeRoleOptions = isAdult
    ? allRelativeRoleOptions.filter((opt) => opt.value !== 2)
    : allRelativeRoleOptions;

  const getDisplayText = <T extends string | number>(
    options: DropdownOption<T>[],
    value: T | null | undefined
  ) => options.find((opt) => opt.value === value)?.displayText || '';

  const toggleSpecies = (species: string) => {
    setPreferredSpeciesTypes((prev) =>
      prev.includes(species)
        ? prev.filter((item) => item !== species)
        : [...prev, species]
    );
  };

  return (
    <Window title="Настройка семьи" width={600} height={880}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <h2 style={{ textAlign: 'center' }}>
              Настройка семейных отношений
            </h2>
          </Stack.Item>

          <Stack.Item>
            <Box style={{ marginBottom: '4px', fontWeight: 'bold' }}>
              Семейная роль:
            </Box>

            <Dropdown
              options={familyTypeOptions.map((opt) => opt.displayText)}
              selected={getDisplayText(familyTypeOptions, familyType)}
              onSelected={(selectedText) => {
                const selectedOption = familyTypeOptions.find(
                  (opt) => opt.displayText === selectedText
                );
                if (selectedOption) {
                  setFamilyType(selectedOption.value);
                }
              }}
              width="100%"
            />

            <Box style={hintStyle}>{tooltips[familyType]}</Box>
          </Stack.Item>

          {familyType !== 'none' && (
            <>
              <Stack.Divider />

              <Stack.Item>
                <Box style={{ marginBottom: '4px' }}>
                  Предпочтение по расе:
                </Box>

                <Dropdown
                  options={speciesOptions.map((opt) => opt.displayText)}
                  selected={getDisplayText(
                    speciesOptions,
                    speciesPreferenceMode
                  )}
                  onSelected={(selectedText) => {
                    const selectedOption = speciesOptions.find(
                      (opt) => opt.displayText === selectedText
                    );
                    if (selectedOption) {
                      setSpeciesPreferenceMode(selectedOption.value);
                    }
                  }}
                  width="100%"
                />
              </Stack.Item>

              {speciesPreferenceMode === 'SPECIFIC_TYPE' && (
                <Stack.Item>
                  <Box style={{ marginBottom: '6px' }}>
                    Выберите одну или несколько рас:
                  </Box>

                  <Box
                    style={{
                      border: '1px solid #555',
                      padding: '6px',
                      maxHeight: '220px',
                      overflowY: 'auto',
                    }}>
                    <Stack vertical>
                      {speciesList.map((species) => {
                        const selected =
                          preferredSpeciesTypes.includes(species);

                        return (
                          <Stack.Item key={species}>
                            <Button
                              fluid
                              selected={selected}
                              color={selected ? 'good' : undefined}
                              onClick={() => toggleSpecies(species)}>
                              {selected ? `✓ ${species}` : species}
                            </Button>
                          </Stack.Item>
                        );
                      })}
                    </Stack>
                  </Box>

                  <Box
                    style={{
                      marginTop: '6px',
                      fontSize: '12px',
                      color: '#aaa',
                    }}>
                    Выбрано:{' '}
                    {preferredSpeciesTypes.length > 0
                      ? preferredSpeciesTypes.join(', ')
                      : 'ничего'}
                  </Box>
                </Stack.Item>
              )}

              <Stack.Item>
                <Box style={{ marginBottom: '4px' }}>
                  Предпочтительная анатомия:
                </Box>

                <Dropdown
                  options={anatomyOptions.map((opt) => opt.displayText)}
                  selected={getDisplayText(
                    anatomyOptions,
                    preferredSpeciesAnatomy
                  )}
                  onSelected={(selectedText) => {
                    const selectedOption = anatomyOptions.find(
                      (opt) => opt.displayText === selectedText
                    );
                    if (selectedOption) {
                      setPreferredSpeciesAnatomy(selectedOption.value);
                    }
                  }}
                  width="100%"
                />
              </Stack.Item>

              <Stack.Item>
                <Box style={{ marginBottom: '4px' }}>
                  Предпочтение по полу:
                </Box>

                <Dropdown
                  options={genderOptions.map((opt) => opt.displayText)}
                  selected={getDisplayText(genderOptions, genderPreference)}
                  onSelected={(selectedText) => {
                    const selectedOption = genderOptions.find(
                      (opt) => opt.displayText === selectedText
                    );
                    if (selectedOption) {
                      setGenderPreference(selectedOption.value);
                    }
                  }}
                  width="100%"
                />
              </Stack.Item>

              {familyType === 'member' && (
                <Stack.Item>
                  <Box style={{ marginBottom: '4px' }}>
                    Желаемая роль в семье:
                  </Box>

                  <Dropdown
                    options={relativeRoleOptions.map((opt) => opt.displayText)}
                    selected={getDisplayText(
                      relativeRoleOptions,
                      desiredRelativeRole
                    )}
                    onSelected={(selectedText) => {
                      const selectedOption = relativeRoleOptions.find(
                        (opt) => opt.displayText === selectedText
                      );
                      if (selectedOption) {
                        setDesiredRelativeRole(selectedOption.value);
                      }
                    }}
                    width="100%"
                  />

                  <Box style={hintStyle}>
                    Система попытается подобрать именно эту роль. Если не
                    получится — роль определяется по возрасту.
                  </Box>
                </Stack.Item>
              )}

              {(familyType === 'couple' || familyType === 'parent') && (
                <Stack.Item>
                  <Box style={{ marginBottom: '4px' }}>Многобрачие:</Box>

                  <Dropdown
                    options={polygamyOptions.map((opt) => opt.displayText)}
                    selected={getDisplayText(polygamyOptions, polygamyMode)}
                    onSelected={(selectedText) => {
                      const selectedOption = polygamyOptions.find(
                        (opt) => opt.displayText === selectedText
                      );
                      if (selectedOption) {
                        setPolygamyMode(selectedOption.value);
                      }
                    }}
                    width="100%"
                  />
                </Stack.Item>
              )}

              <Stack.Item>
                <Button
                  fluid
                  selected={allowLowStatusMarriage === 1}
                  color={allowLowStatusMarriage === 1 ? 'average' : undefined}
                  onClick={() =>
                    setAllowLowStatusMarriage(
                      allowLowStatusMarriage === 1 ? 0 : 1
                    )
                  }>
                  {allowLowStatusMarriage === 1
                    ? 'Брак с низким статусом: разрешён'
                    : 'Брак с низким статусом: запрещён'}
                </Button>

                <Box style={hintStyle}>
                  Высокий статус + низкий статус = запрещено всегда. Остальные
                  могут снять защиту вручную.
                </Box>
              </Stack.Item>

              <Stack.Item>
                <Input
                  placeholder="Имя фаворита"
                  value={favoriteName}
                  onChange={(value) => setFavoriteName(String(value))}
                  fluid
                />
                <Box style={hintStyle}>
                  Если указан фаворит — система ищет его первым, игнорируя все
                  ограничения. Ожидание бессрочное.
                </Box>
              </Stack.Item>
            </>
          )}

          <Stack.Item>
            <Box style={{ ...hintStyle, textAlign: 'center' as const }}>
              При сторителлере Ксайликс все ограничения (кроме пола) могут быть
              сняты. Семейная рулетка непредсказуема.
            </Box>
          </Stack.Item>

          <Stack.Item mt={2}>
            <Button
              fluid
              color="good"
              onClick={() => {
                act('save', {
                  familyType,
                  speciesPreferenceMode,
                  preferredSpeciesTypes: [...preferredSpeciesTypes],
                  preferredSpeciesAnatomy,
                  genderPreference,
                  favoriteName,
                  polygamyMode,
                  desiredRelativeRole,
                  allowLowStatusMarriage,
                });
              }}>
              Сохранить настройки
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
