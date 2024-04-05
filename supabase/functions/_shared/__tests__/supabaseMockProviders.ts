export const getUpdateWithEqMock = (responseMock: any) => {
  const eqMock = () => Promise.resolve(responseMock);
  const updateMock = () => ({ eq: eqMock });
  return {
    update: updateMock,
  };
};

export const getSelectWithInMock = (responseMock: any) => {
  const inMock = () => Promise.resolve(responseMock);
  const selectMock = () => ({ in: inMock });
  return {
    select: selectMock,
  };
};

export const getSelectWithEqMock = (responseMock: any) => {
  const eqMock = () => Promise.resolve(responseMock);
  const selectMock = () => ({ eq: eqMock });
  return {
    select: selectMock,
  };
};

export const getInsertMock = (responseMock: any) => {
  const insertMock = () => Promise.resolve(responseMock);
  return {
    insert: insertMock,
  };
};
export const getInsertWithSelectMock = (responseMock: any) => {
  const selectMock = () => Promise.resolve(responseMock);
  const insertMock = () => ({ select: selectMock });
  return {
    insert: insertMock,
  };
};
