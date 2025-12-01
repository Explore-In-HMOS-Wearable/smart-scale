import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { getGlobalContext } from '../entryability/EntryAbility';
import { Weight } from '../model/WeightModel';

class RdbService {
  private static instance: RdbService;
  private store: relationalStore.RdbStore | null = null;
  private dbName = '';

  private constructor() {
  }

  static getInstance(): RdbService {
    if (!RdbService.instance) {
      RdbService.instance = new RdbService();
    }
    return RdbService.instance;
  }

  async init(dbName: string = 'app.db') {
    if (this.store) {
      return this;
    }

    this.dbName = dbName;

    const config: relationalStore.StoreConfig = {
      name: this.dbName,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.store = await relationalStore.getRdbStore(getGlobalContext(), config);

    return this;
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('RDB store not initialized. Call init() first.');
    }
    return this.store;
  }

  async registerTable(createSql: string) {
    const store = this.ensureStore();
    await store.executeSql(createSql);
    return true;
  }

  async insertWeightData(weight: number): Promise<number | null> {
    const store = this.ensureStore();
    return new Promise<number | null>((resolve) => {
      const bucket: relationalStore.ValuesBucket = {
        'WEIGHT': Number(weight.toFixed(2))
      };
      store.insert('WEIGHT', bucket, (err: BusinessError, rowId: number) => {
        if (err) {
          resolve(0);
          return;
        }
        resolve(rowId);
      })
    });
  }

  async getAllData(): Promise<Weight[]> {
    const store = this.ensureStore();
    return new Promise<Weight[]>(async (resolve) => {
      const sql = `SELECT * FROM WEIGHT ORDER BY ID DESC`;
      const items: Array<Weight> = [];

      try {
        const resultSet = await store.querySql(sql, []);

        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          const weight = resultSet.getDouble(resultSet.getColumnIndex('WEIGHT'));
          let data: Weight = {
            ID: id,
            WEIGHT: weight
          }
          items.push(data);
        }

        resolve(items)
        resultSet.close();

      } catch (err) {
        resolve([])
      }
    });
  }

  async deleteDataById(id: number): Promise<boolean> {
    const store = this.ensureStore();
    return new Promise<boolean>(async (resolve) => {
      const sql = `DELETE FROM WEIGHT WHERE ID= ${id}`;
      try {
        await store.executeSql(sql);
        resolve(true);
      } catch (err) {
        resolve(false)
      }
    })
  }

  async getLimitedRecord(limit: number = 1): Promise<Weight[]> {
    const store = this.ensureStore();
    const sql = `SELECT * FROM WEIGHT ORDER BY ID DESC LIMIT ${limit}`;
    const items: Weight[] = [];

    return new Promise<Weight[]>(async (resolve) => {
      try {
        const resultSet = await store.querySql(sql, []);

        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          const weight = resultSet.getDouble(resultSet.getColumnIndex('WEIGHT'));

          items.push({
            ID: id,
            WEIGHT: weight
          });
        }

        resultSet.close();
        resolve(items);

      } catch (error) {
        resolve([]);
      }
    })

  }
}

export default RdbService.getInstance();
